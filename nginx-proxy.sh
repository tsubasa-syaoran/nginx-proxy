#!/usr/bin/env bash

set -e

red(){ echo -e "\033[31m\033[01m$*\033[0m"; }
green(){ echo -e "\033[32m\033[01m$*\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$*\033[0m"; }
blue(){ echo -e "\033[36m\033[01m$*\033[0m"; }

ask_info(){

    read -rp "请输入域名: " DOMAIN
    read -rp "请输入本地端口: " PORT

    if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
        red "域名或端口不能为空"
        exit 1
    fi
}

install_base(){

    yellow "安装依赖..."

    apt update

    apt install -y nginx certbot python3-certbot-nginx
}

check_port(){

    if ! ss -tulpn | grep -q ":$PORT "; then
        red "端口 $PORT 未运行"
        exit 1
    fi

    green "检测到端口 $PORT 正在运行"
}

create_nginx(){

    yellow "创建 nginx 配置..."

cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {

        proxy_pass http://localhost:$PORT;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

    nginx -t

    systemctl reload nginx

    green "nginx 配置完成"
}

install_ssl(){

    yellow "申请 SSL 证书..."

    certbot --nginx \
        -d $DOMAIN \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --redirect

    green "SSL 申请成功"
}

show_result(){

    echo

    green "====================================="
    green "部署完成"
    green "====================================="

    echo

    blue "访问地址:"
    echo "https://$DOMAIN"

    echo

    blue "反代端口:"
    echo "$PORT"
}

main(){

    ask_info

    install_base

    check_port

    create_nginx

    install_ssl

    show_result
}

main

