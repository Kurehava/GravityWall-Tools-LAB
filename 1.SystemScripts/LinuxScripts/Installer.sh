DEBIAN_FRONTEND=noninteractive
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install -y init systemd zsh net-tools dnsutils \
    iputils-ping curl wget vim neofetch git sudo lsof \
    traceroute iproute2 gcc screen ssh bashtop apt-utils \
    telnet zip
sudo DEBIAN_FRONTEND=noninteractive apt install -y tzdata
sudo apt install -y tightvncserver xfonts-75dpi xfonts-100dpi xfonts-base
bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/KENSYO/ZSH_KENSYO_AUTO.sh")
echo 'TZ="Asia/Tokyo"' >> /root/.zshrc
echo 'alias maintenance="sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y"' >> /root/.zshrc
