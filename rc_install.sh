#!/bin/bash
set -euo pipefail

TARGET_VERSION="${TARGET_VERSION:-1.6.10}"
ROUNDCUBE_DB="${ROUNDCUBE_DB:-roundcube}"
ROUNDCUBE_DB_USER="${ROUNDCUBE_DB_USER:-roundcube}"
ROUNDCUBE_DB_PASS="${ROUNDCUBE_DB_PASS:-fearsoff.org}"
TEST_USER="${TEST_USER:-roundcube}"
TEST_PASS="${TEST_PASS:-fearsoff.org}"

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export UCF_FORCE_CONFFOLD=1
export DEBIAN_PRIORITY=critical

debconf-set-selections <<'EOF'
postfix postfix/main_mailer_type select Local only
postfix postfix/mailname string localhost
EOF

debconf-set-selections <<'EOF'
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC
EOF

ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

echo "[1/9] Installing packages..."
apt-get update -qq
apt-get install -yq --no-install-recommends \
  apache2 \
  php php-ldap php-mysql php-intl php-mbstring php-xml php-common php-cli php-curl php-zip php-gd php-imagick \
  unzip mariadb-server dovecot-imapd dovecot-pop3d composer bsd-mailx wget curl postfix ca-certificates

if [ ! -d "/opt/roundcube-${TARGET_VERSION}" ]; then
  echo "[2/9] Downloading Roundcube ${TARGET_VERSION}..."
  cd /tmp
  wget -O roundcubemail.tar.gz "https://github.com/roundcube/roundcubemail/releases/download/${TARGET_VERSION}/roundcubemail-${TARGET_VERSION}-complete.tar.gz"
  rm -rf roundcubemail
  mkdir roundcubemail
  tar --strip-components=1 -xzf roundcubemail.tar.gz -C roundcubemail
  mv roundcubemail "/opt/roundcube-${TARGET_VERSION}"

  echo "[3/9] Installing Composer deps..."
  cd "/opt/roundcube-${TARGET_VERSION}"
  [ -f composer.json ] || cp composer.json-dist composer.json
  composer install --no-dev --optimize-autoloader

  chown -R www-data:www-data "/opt/roundcube-${TARGET_VERSION}"
fi

echo "[4/9] Linking active Roundcube version..."
rm -rf /var/www/html/roundcube
ln -s "/opt/roundcube-${TARGET_VERSION}" /var/www/html/roundcube

echo "[5/9] Apache config..."
cat > /etc/apache2/sites-available/roundcube.conf <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/roundcube

    <Directory /var/www/html/roundcube>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2ensite roundcube.conf >/dev/null
a2enmod rewrite >/dev/null
a2dissite 000-default.conf >/dev/null || true
echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf
a2enconf servername >/dev/null

echo "[6/9] Roundcube config..."
cp /var/www/html/roundcube/config/config.inc.php.sample /var/www/html/roundcube/config/config.inc.php || true
sed -i "s#^\$config\['db_dsnw'\].*#\$config['db_dsnw'] = 'mysql://${ROUNDCUBE_DB_USER}:${ROUNDCUBE_DB_PASS}@localhost/${ROUNDCUBE_DB}';#" /var/www/html/roundcube/config/config.inc.php
grep -q "default_host" /var/www/html/roundcube/config/config.inc.php || echo "\$config['default_host'] = 'localhost';" >> /var/www/html/roundcube/config/config.inc.php
grep -q "smtp_server" /var/www/html/roundcube/config/config.inc.php || echo "\$config['smtp_server'] = 'localhost';" >> /var/www/html/roundcube/config/config.inc.php

echo "[7/9] Dovecot config..."
sed -i "s|^#mail_location =.*|mail_location = mbox:~/mail:INBOX=/var/mail/%u|" /etc/dovecot/conf.d/10-mail.conf
sed -i "s|^#disable_plaintext_auth =.*|disable_plaintext_auth = no|" /etc/dovecot/conf.d/10-auth.conf
sed -i "s|^auth_mechanisms =.*|auth_mechanisms = plain login|" /etc/dovecot/conf.d/10-auth.conf

echo "[8/9] Creating test user..."
id "${TEST_USER}" >/dev/null 2>&1 || useradd -m "${TEST_USER}"
echo "${TEST_USER}:${TEST_PASS}" | chpasswd

echo "[9/9] Cleaning installer..."
rm -rf /var/www/html/roundcube/installer
chown -R www-data:www-data /var/www/html/roundcube
