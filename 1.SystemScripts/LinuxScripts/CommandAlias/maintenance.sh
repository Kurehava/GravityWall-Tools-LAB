# centos 8+
alias maintenance="sudo dnf makecache && sudo dnf -y upgrade && sudo dnf -y autoremove"

# CentOS 7
alias maintenance="sudo yum makecache && sudo yum -y update && sudo yum -y autoremove"

# ubuntu & debian
alias maintenance="sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove"
