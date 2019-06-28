#!/usr/bin/env bash 
# Install docker-ss
# Auther: Air
# OS: Ubuntu18.04
# 2019.4.27 first commint
# 2019.5.22 Redesign

# Color setings     # Meaning
RED='\033[0;31m'    # RED: error
GREEN='\033[0;32m'  # GREEN: success
YELLOW='\033[0;33m' # YELLOW: warning
PLAIN='\033[0m' 	# PLAIN: reset color


CUR_DIR=$(pwd)

# get ip address
get_ip() {
	ipaddr=$(curl -sS ifconfig.me)

	echo ${ipaddr}
}


# check root
check_root() {
	[[ $EUID -ne 0 ]] && echo -e "[${RED}Error${PLAIN}] This script must be run as root!" && exit 1
}

# check docker
# 0 installed 1 Not Installed
check_docker() {
	if [[ `command -v docker` -eq 0 ]]; then
		echo -e "[ ${YELLOW}Warning${PLAIN} ] Docker has been installed"
		return 0
	elif [[ `command -v docker` -ne 0 ]]; then
		return 1
	fi
}

# install docker on vps
install_docker() {
	apt-get update -y && \
	apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -  && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository \
   		"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   		$(lsb_release -cs) \
   		stable"  && \
   	apt-get update -y && \
   	apt-get install docker-ce docker-ce-cli containerd.io docker-compose -y && \

   	return 0
}

# get docker-compose configurition
get_config() {
	clear
	echo "Please chose your Password"
	read -p "(Default password: admin) " passwd
	echo "Please chose your port"
	read -p "(Default password: random) " port

	if [[ -z ${passwd} ]]; then
		passwd="admin"
	elif [[ -z ${port} ]]; then
		port="$(shuf -i 1024-65535 -n 1)"
	fi

	cat > docker-compose.yaml <<-EOF
shadowsocks:
  image: shadowsocks/shadowsocks-libev
  ports:
    - "$port:8388"
  environment:
    - METHOD=aes-256-gcm
    - PASSWORD=$passwd
  restart: always
EOF
	return 0
}

main() {
	clear
	check_root
	cd $HOME
	if [[ -d ${CUR_DIR}/docker ]]; then
		echo "[ ${YELLOW}Warning{PLAIN}] $HOME/docker is exists"
	else
		mkdir -p ${CUR_DIR}/docker/ss-libev
	fi
	
	cd ${CUR_DIR}/docker/ss-libev
	if [[ $? -eq 0 ]]; then
		check_docker || install_docker	
	else
		echo -e "[ ${RED}Error${PLAIN} ] Failed to create folder"
		exit 1
	fi
	get_config
	if [[ $? -eq 0 ]]; then
		docker-compose up -d

		clear
		echo -e "Your server ip             : ${GREEN} $(get_ip) ${PLAIN}"		
		echo -e "Your port                  : ${GREEN} ${port} ${PLAIN}"
		echo -e "Your encryption method     : ${GREEN} aes-256-gcm ${PLAIN}"
		echo -e "Your password              : ${GREEN} $passwd ${PLAIN}"
		echo 
	fi


}

main

