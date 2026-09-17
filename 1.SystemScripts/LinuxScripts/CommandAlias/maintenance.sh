# RHEL系
alias maintenance='PM=$(command -v dnf || command -v yum) && sudo "$PM" -y upgrade && sudo "$PM" -y autoremove'

# ubuntu & debian
alias maintenance='sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove'

# ubuntu & debian full-upgrade
alias maintenance_full='sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove'

# ubuntu & debian both
alias maintenance='sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove'
alias maintenance_full='sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confold" full-upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove'
