apt update -y && apt upgrade -y && apt autoremove -y
apt install curl wget sudo neofetch net-tools apt-utils jq vim ssh git gcc g++ screen lsof bpytop -y

# needs
apt install ufw (or iptables)
 
# Docker
# 文字化け
apt update -y && apt upgrade -y && apt autoremove -y
apt apt-get install -y language-pack-ja-base language-pack-ja locales
locale-gen ja_JP.UTF-8
# ↓将下面的代码添加到.zshrc或者.bashrc
export LANG=C.UTF-8
export LANGUAGE=en_US
