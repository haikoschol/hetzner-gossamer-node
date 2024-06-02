#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt update && apt upgrade -y

PACKAGES="apt-transport-https ca-certificates lsb-release unattended-upgrades ufw curl wget gnupg git zsh tmux fzf fd-find lsd vim-nox golang caddy"
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

cd $HOME
wget https://github.com/caddyserver/xcaddy/releases/download/v0.4.2/xcaddy_0.4.2_linux_amd64.deb
dpkg -i xcaddy_0.4.2_linux_amd64.deb
xcaddy build --with github.com/caddy-dns/hetzner
cp caddy /usr/bin/caddy

mkdir -p /etc/caddy
cat <<EOL > /etc/caddy/Caddyfile
grafana.zeropatience.net {
    reverse_proxy * localhost:3000

    tls {
        dns hetzner {env.HETZNER_DNS_TOKEN}
    }
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
sudo -u ${USERNAME} git clone https://github.com/ChainSafe/gossamer.git /home/${USERNAME}/gossamer

reboot
