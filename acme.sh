#!/bin/sh

red(){ echo -e "\033[31m$1\033[0m"; }
green(){ echo -e "\033[32m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

[ "$(id -u)" != "0" ] && echo "请用root运行" && exit

install_env(){

green "安装依赖..."

opkg update >/dev/null 2>&1

opkg install curl socat wget openssl-util tar bind-dig >/dev/null 2>&1

}

install_acme(){

green "安装 acme.sh"

curl https://get.acme.sh | sh

export PATH=~/.acme.sh:$PATH

}

stop80(){

pid=$(netstat -lnpt 2>/dev/null | grep :80 | awk '{print $7}' | cut -d/ -f1)

if [ -n "$pid" ]; then

yellow "释放80端口..."

kill -9 $pid

fi

}

get_ip(){

v4=$(curl -s4 icanhazip.com)

v6=$(curl -s6 icanhazip.com)

}

check_ip(){

get_ip

domain_ip=$(dig +short $domain | head -n1)

if [ "$domain_ip" != "$v4" ] && [ "$domain_ip" != "$v6" ]; then

red "域名解析IP不匹配"

echo "域名IP: $domain_ip"

echo "本机IP: $v4 $v6"

exit

fi

}

install_cert(){

mkdir -p /etc

~/.acme.sh/acme.sh --install-cert -d $domain \
--ecc \
--key-file /etc/privkey.pem \
--fullchain-file /etc/fullchain.pem

green "证书安装完成"

echo
echo "证书:"
echo "/etc/fullchain.pem"

echo
echo "私钥:"
echo "/etc/privkey.pem"

}

issue80(){

read -p "输入域名: " domain

read -p "邮箱(可回车): " email

[ -z "$email" ] && email="$(date +%s)@gmail.com"

~/.acme.sh/acme.sh --register-account -m $email

check_ip

stop80

green "申请证书..."

~/.acme.sh/acme.sh \
--issue -d $domain \
--standalone \
-k ec-256

install_cert

}

dns_cf(){

read -p "域名: " domain

read -p "Cloudflare Email: " CF_Email
read -p "Cloudflare API Key: " CF_Key

export CF_Email
export CF_Key

~/.acme.sh/acme.sh \
--issue --dns dns_cf \
-d $domain \
-k ec-256

install_cert

}

dns_ali(){

read -p "域名: " domain

read -p "Aliyun Key: " Ali_Key
read -p "Aliyun Secret: " Ali_Secret

export Ali_Key
export Ali_Secret

~/.acme.sh/acme.sh \
--issue --dns dns_ali \
-d $domain \
-k ec-256

install_cert

}

dns_dp(){

read -p "域名: " domain

read -p "DNSPod ID: " DP_Id
read -p "DNSPod Key: " DP_Key

export DP_Id
export DP_Key

~/.acme.sh/acme.sh \
--issue --dns dns_dp \
-d $domain \
-k ec-256

install_cert

}

renew(){

~/.acme.sh/acme.sh --cron

green "续期完成"

}

menu(){

clear

echo "================================"
echo "       OpenWrt ACME脚本"
echo "================================"

echo
echo "1 安装环境"
echo "2 80端口申请证书"
echo "3 Cloudflare DNS申请"
echo "4 Aliyun DNS申请"
echo "5 DNSPod申请"
echo "6 手动续期"
echo "0 退出"
echo

read -p "选择: " num

case "$num" in

1) install_env && install_acme ;;
2) issue80 ;;
3) dns_cf ;;
4) dns_ali ;;
5) dns_dp ;;
6) renew ;;
0) exit ;;

esac

}

menu
