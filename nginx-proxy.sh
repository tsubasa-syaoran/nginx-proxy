```bash
#!/bin/bash

# ==========================================
# Nginx Reverse Proxy + SSL Auto Setup
# 支持：
# - 自动反向代理到指定端口
# - 自动申请 HTTPS 证书
# - 自动配置 nginx
# - 自动开启 HTTPS
#
# 使用：
# ==========================================

set -e

echo "======================================"
echo " Nginx HTTPS 自动配置脚本"
echo "======================================"

# 输入域名
read -p "请输入域名（例如 status.nekomini.site）: " DOMAIN

# 输入端口
read -p "请输入需要反代的本地端口（例如 3001）: " PORT

# 检查输入
if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
    echo "域名或端口不能为空"
    exit 1
fi

echo ""
echo "开始安装依赖..."

apt update
apt install -y nginx certbot python3-certbot-nginx

echo ""
echo "创建 nginx 配置..."

CONFIG_FILE="/etc/nginx/sites-available/$DOMAIN"

cat > $CONFIG_FILE <<EOF
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

echo ""
echo "启用站点..."

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

echo ""
echo "检查 nginx 配置..."

nginx -t

echo ""
echo "重载 nginx..."

systemctl reload nginx

echo ""
echo "开始申请 HTTPS 证书..."

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN --redirect

echo ""
echo "======================================"
echo " HTTPS 配置完成"
echo "======================================"

echo ""
echo "访问地址："
echo "https://$DOMAIN"

echo ""
echo "反代端口："
echo "localhost:$PORT"

echo ""
echo "nginx 配置文件："
echo "$CONFIG_FILE"

echo ""
echo "证书自动续期已启用"
```
