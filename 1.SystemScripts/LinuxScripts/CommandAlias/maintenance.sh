# centos
alias maintenance="sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove"

# ubuntu & debian
alias maintenance="sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove"
