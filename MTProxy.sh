#!/usr/bin/env bash 
# Author: Air
# Date: 2019-6-1
# Auto install MTProxy shell scripts
# OS: Ubuntu18.04 / Debian 9.x
# Version: 0.1
# 
current_dir=$(pwd)

get_config() {
    random_port=$(shuf -i 30000-65535 -n 1)
    secret=$(head -c 16 /dev/urandom | xxd -ps)
    echo -e "Passwd: $secret\nport: $random_port" > config.txt
    cat > /etc/systemd/system/MTProxy.service <<-EOF
[Unit]
Description=MTProxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/MTProxy/
ExecStart=/usr/local/MTProxy/mtproto-proxy -u nobody -p 8888 -H $random_port -S $secret --aes-pwd proxy-secret proxy-multi.conf -M 1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable MTProxy.service
	systemctl restart MTProxy.service

}


main() {
    # Install dependence and make it
    clear
    apt install git curl build-essential libssl-dev zlib1g-dev -y && \
    git clone https://github.com/TelegramMessenger/MTProxy && \
    cd $current_dir/MTProxy || exit 1 && \
    make && \
    cd $current_dir/objs/bin || echo "Dir not found" && exit 1 && \
    makir -p /usr/local/MTProxy/ && \
    cp $current_dir/mtproto-proxy /usr/local/MTProxy/ && \
	cd /usr/local/MTProxy/ && \
	curl -s https://core.telegram.org/getProxySecret -o proxy-secret && \
	curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
	 
	if [ $? -eq 0 ]; then
		get_config
		clear
		echo "---------Attention---------------"
		echo "Your password and port in config.txt"
		echo "Usage: tg://proxy?server=YOUR_SERVER_IP&port=PORT&secret=password"
		echo 
		echo "----------------------------------"
	fi

}

main
