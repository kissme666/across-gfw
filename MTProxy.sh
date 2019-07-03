#!/usr/bin/env bash 
# Author: Air
# Date: 2019-6-1
# Auto install MTProxy shell scripts
# OS: Ubuntu18.04 / Debian 9.x
# Version: 0.2
# 原版协议已被识别，暂时放弃等更新

# debug
# set -x 


current_dir=$(pwd)

# 获取ip地址
get_ip() {
	local ipaddr=$(curl ifconfig.me)

	echo "$ipaddr"
}

# 配置端口密码
get_config() {
    random_port=$(shuf -i 30000-65535 -n 1)
    secret=$(head -c 16 /dev/urandom | xxd -ps)

    echo "Usage: tg://proxy?server=$(get_ip)&port=${random_port}&secret=${secret}" > $HOME/mtproxy.txt
}


# 设置mtproxy为系统开启启动服务
enable_mtproxy() {
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

	return 0
}

# 输出安装后的信息
print_info() {
	clear
	echo 
	echo -e " MTProxy IS INSTALLED                                "
	echo -e " Your password and port in $HOME/mtproxy.txt         "
	echo -e " $(cat $HOME/mtproxy.txt )                           "
	echo 
	echo 

		return 0
}

# 删除安装过程中产生的文件
clean() {
	rm -rf $HOME/MTProxy

	return 0

}
# 准备编译编译安装
pre_install() {
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


# 安装程序
install_mtproxy() {
	pre_install \
	&& get_config \
	&& enable_mtproxy \
	&& print_info \
	&& clean

}

# 卸载mtproxy 这里应该检查是否安装mrpoxy，尚未实现
uninstall_mtproxy() {
	systemctl stop MTProxy.service &>/dev/null \
	&& systemctl disable MTProxy.service &> /dev/null
	rm -rf /usr/local/MTProxy 
	rm -f /etc/systemd/system/MTProxy.service
	rm -f $HOME/mtproxy.txt
	echo "Uninstall mtproxy successfuly."
}



# 入口
action=$1
[ -z $1 ] && action='install'
case "$action" in
	install|uninstall)
		${action}_mtproxy
		;;
	*)
		echo "Arguements error! [${action}]"
		echo "Usage: $(basename $0) [install|uninstall]"
		;;
esac
