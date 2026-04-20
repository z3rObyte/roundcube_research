#!/bin/bash
set -euo pipefail

TARGET_VERSION=${TARGET_VERSION:-1.6.10}
ROUNDCUBE_DB=${ROUNDCUBE_DB:-roundcube}
ROUNDCUBE_DB_USER=${ROUNDCUBE_DB_USER:-roundcube}
ROUNDCUBE_DB_PASS=${ROUNDCUBE_DB_PASS:-Roundcube.123}
TEST_USER=${TEST_USER:-roundcube}
TEST_PASS=${TEST_PASS:-Roundcube.123}

cleanup() {
  mysqladmin shutdown --silent --socket=/run/mysqld/mysqld.sock 2>/dev/null || true
}
trap cleanup EXIT

echo "Roundcube $TARGET_VERSION"

# PHP
phpenmod mysql intl mbstring xml zip gd curl 2>/dev/null || true

# MariaDB
mkdir -p /run/mysqld /var/log/mysql /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/log/mysql /var/lib/mysql

[ ! -d /var/lib/mysql/mysql ] && mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db

# MariaDB start
mysqld_safe --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --skip-networking --user=mysql &
sleep 5

# DB setup (mysql directo, SIN heredoc)
mysql --socket=/run/mysqld/mysqld.sock -e "
CREATE DATABASE IF NOT EXISTS \`$ROUNDCUBE_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '$ROUNDCUBE_DB_USER'@'localhost' IDENTIFIED BY '$ROUNDCUBE_DB_PASS';
GRANT ALL PRIVILEGES ON \`$ROUNDCUBE_DB\`.* TO '$ROUNDCUBE_DB_USER'@'localhost';
FLUSH PRIVILEGES;
"
mysql roundcube < /var/www/html/roundcube/SQL/mysql.initial.sql

# Roundcube
[ ! -d /var/www/html/roundcube ] && /root/rc_install.sh

# Config
CONFIG=/var/www/html/roundcube/config/config.inc.php
[ -f "$CONFIG" ] && sed -i "s|\$config\['db_dsnw'\].*|\$config\['db_dsnw'\]\ \=\ 'mysql://$ROUNDCUBE_DB_USER:$ROUNDCUBE_DB_PASS@localhost/$ROUNDCUBE_DB'\;|g" "$CONFIG"

# User
id $TEST_USER 2>/dev/null || useradd -m -s /bin/bash $TEST_USER
echo "$TEST_USER:$TEST_PASS" | chpasswd

# Services
postfix start || true
service dovecot start || true

# Perms
chown -R www-data /var/www/html/roundcube 2>/dev/null || true

echo "Ready: http://127.0.0.1 | $TEST_USER:$TEST_PASS"
exec apache2ctl -D FOREGROUND
