#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt update && apt upgrade -y

PACKAGES="apt-transport-https ca-certificates lsb-release unattended-upgrades build-essential ufw curl wget gnupg git zsh tmux fzf fd-find lsd vim-nox golang caddy"
apt install -y $PACKAGES

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update && apt install -y docker-ce docker-ce-cli containerd.io

DOCKER_CONFIG=${DOCKER_CONFIG:-/root/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

mkdir -p /etc/caddy
cat <<EOL > /etc/caddy/Caddyfile
grafana.zeropatience.net {
    reverse_proxy * localhost:3000
}
EOL

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow https
ufw allow 7001
ufw --force enable

USERNAME=haiko

useradd -g users -G docker,sudo -m -s /usr/bin/zsh ${USERNAME}
mkdir -m 0700 /home/${USERNAME}/.ssh
cp /root/.ssh/authorized_keys /home/${USERNAME}/.ssh
chown -R ${USERNAME}:users /home/${USERNAME}/.ssh
systemctl restart ssh
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}
sudo -u ${USERNAME} git clone https://github.com/${USERNAME}schol/dotfiles.git /home/${USERNAME}/dotfiles
sudo -u ${USERNAME} /home/${USERNAME}/dotfiles/mklinks.sh


sudo -u ${USERNAME} mkdir -p /home/${USERNAME}/.config/systemd/user
${USERNAME} cat <<EOL > /home/${USERNAME}/.config/systemd/user/gossamer.service
[Unit]
Description=Gossamer
Documentation=https://github.com/ChainSafe/gossamer
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=${USERNAME}
Group=users
ExecStart=/home/${USERNAME}/gossamer/bin/gossamer # TODO
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOL

chown -R /home/${USERNAME}/.config/systemd ${USERNAME}
sudo -u ${USERNAME} git clone https://github.com/ChainSafe/gossamer.git /home/${USERNAME}/gossamer
reboot
