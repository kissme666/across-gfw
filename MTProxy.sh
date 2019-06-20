#!/usr/bin/env bash 
# Author: Air
# Date: 2019-6-1
# Auto install MTProxy shell scripts
# OS: Ubuntu18.04 / Debian 9.x
# Version: 0.1
# 

# debug
set -x 


current_dir=$(pwd)

# 获取ip地址
get_ip() {
	local ipaddr=$(curl ipconfig.me)

	echo "$ipaddr"
}

# 配置端口密码
get_config() {
    random_port=$(shuf -i 30000-65535 -n 1)
    secret=$(head -c 16 /dev/urandom | xxd -ps)
    
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

	echo "Usage: tg://proxy?server=$(get_ip)&port=${random_port}&secret=${secret}" | tee $HOME/mtproxy.txt
}


# 输出安装后的信息
print_info() {
		clear
		echo 
		echo -e " MTProxy IS INSTALLED               				  "
		echo -e " Your password and port in $HOME/mtproxy.txt		  "
		echo -e " $(cat $HOME/mtproxy.txt )              			  "
		echo 
		echo 

		return 0
}

# 下载编译安装
install_mtproxy() {
    # Install dependence and make it
    clear
    apt update \
    && apt install -y git curl build-essential libssl-dev zlib1g-dev \
	&& git clone https://github.com/TelegramMessenger/MTProxy \
    && cd $current_dir/MTProxy || exit 1 \
    && make \
    && cd $current_dir/MTProxy/objs/bin || exit 1 \
    && mkdir -p /usr/local/MTProxy/ \
    && cp ./mtproto-proxy /usr/local/MTProxy/ \
	&& cd /usr/local/MTProxy/ \
	&& curl -s https://core.telegram.org/getProxySecret -o proxy-secret \
	&& curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

	return 0
}


# 入口程序
main() {
	install_mtproxy \
	&& get_config \
	&& print_info

}

main