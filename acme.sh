#!/bin/bash

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

[[ $EUID -ne 0 ]] && echo "请使用root运行" && exit

ACME_HOME="/root/.acme.sh"
ACME="$ACME_HOME/acme.sh"

detect_os(){
if grep -qi openwrt /etc/os-release 2>/dev/null; then
release="OpenWrt"
elif [ -f /etc/redhat-release ]; then
release="Centos"
elif grep -qi debian /etc/os-release; then
release="Debian"
elif grep -qi ubuntu /etc/os-release; then
release="Ubuntu"
else
release="Unknown"
fi
}

install_dep(){

green "安装依赖..."

if [[ $release == "OpenWrt" ]]; then
opkg update
opkg install curl wget socat jq tar openssl-util bind-dig
/etc/init.d/cron enable
/etc/init.d/cron start

elif command -v apt >/dev/null 2>&1; then
apt update
apt install -y curl wget socat jq dnsutils cron

elif command -v yum >/dev/null 2>&1; then
yum install -y curl wget socat jq bind-utils cronie
fi
}

install_acme(){

if [ ! -f "$ACME" ]; then
green "安装 acme.sh..."
curl https://get.acme.sh | sh

if [ ! -f "$ACME" ]; then
red "acme.sh 安装失败"
exit 1
fi
fi

source ~/.bashrc 2>/dev/null
}

issue_standalone(){

read -p "请输入域名: " DOMAIN

green "开始申请证书..."

$ACME --issue \
--standalone \
-d $DOMAIN \
-k ec-256

install_cert $DOMAIN
}

issue_dns(){

read -p "请输入域名: " DOMAIN

echo "选择DNS服务商"
echo "1 Cloudflare"
echo "2 Aliyun"
echo "3 DNSPod"

read -p "选择: " dns

case $dns in

1)
read -p "CF_Key: " CF_Key
read -p "CF_Email: " CF_Email

export CF_Key
export CF_Email

$ACME --issue \
--dns dns_cf \
-d $DOMAIN \
-k ec-256
;;

2)
read -p "Ali_Key: " Ali_Key
read -p "Ali_Secret: " Ali_Secret

export Ali_Key
export Ali_Secret

$ACME --issue \
--dns dns_ali \
-d $DOMAIN \
-k ec-256
;;

3)
read -p "DP_Id: " DP_Id
read -p "DP_Key: " DP_Key

export DP_Id
export DP_Key

$ACME --issue \
--dns dns_dp \
-d $DOMAIN \
-k ec-256
;;

esac

install_cert $DOMAIN
}

install_cert(){

DOMAIN=$1

mkdir -p /etc/ssl/acme

$ACME --install-cert -d $DOMAIN \
--key-file /etc/privkey.pem \
--fullchain-file /etc/fullchain.pem \

green "证书安装完成"
echo "/etc/privkey.pem"
echo "/etc/fullchain.pem"
}

list_cert(){

$ACME --list
}

renew_cert(){

green "开始续期证书..."

$ACME --cron
}

uninstall_acme(){

$ACME --uninstall
rm -rf ~/.acme.sh
rm -rf /etc/ssl/acme

green "acme.sh 已卸载"
}

menu(){

clear
echo "================================"
echo " ACME 证书管理脚本"
echo "================================"
echo "1 申请证书 (80端口)"
echo "2 申请证书 (DNS API)"
echo "3 查看证书"
echo "4 手动续期"
echo "5 卸载"
echo "0 退出"
echo "================================"

read -p "选择: " num

case "$num" in

1) issue_standalone ;;
2) issue_dns ;;
3) list_cert ;;
4) renew_cert ;;
5) uninstall_acme ;;
0) exit ;;

esac
}

detect_os
install_dep
install_acme
menu
