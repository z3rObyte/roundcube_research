# roundcube_research
This lab allows you to quickly deploy different versions of roundcube instances with Docker, for researching and security testing purposes.
## Requirements
The only requirement is to have Docker Engine installed. You can copy & paste commands below to install them (from official Docker Docs):
* Debian installation
```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
* Ubuntu installation
```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
## Usage
Currently, we can deploy the following Roundcube versions: `1.4.10` and `1.6.10` to `1.6.15` (you can easily add more versions to `docker-compose.yml`).
To deploy them use `docker compose` command:
```bash
# Roundcube 1.4.10 | available at localhost:1410
sudo docker compose up roundcube-1410

# Roundcube 1.6.10 | available at localhost:1610
sudo docker compose up roundcube-1610

# Roundcube 1.6.11 | available at localhost:1611
sudo docker compose up roundcube-1611

# Roundcube 1.6.12 | available at localhost:1612
sudo docker compose up roundcube-1612

# Roundcube 1.6.13 | available at localhost:1613
sudo docker compose up roundcube-1613

# Roundcube 1.6.14 | available at localhost:1614
sudo docker compose up roundcube-1614

# Roundcube 1.6.15 | available at localhost:1615
sudo docker compose up roundcube-1615
```
The default credentials for logging in are:
```txt
Username: roundcube
Password: Roundcube.123
```
Happy hacking!
