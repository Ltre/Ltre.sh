#!/bin/bash

# 定义域名列表文件的路径(文件中，每行一个域名，注意，必须是通过certbot申请Let's Encrypt证书的域名)
DOMAIN_LIST_FILE="/etc/haproxy/domains.txt"

# 检查域名列表文件是否存在
if [ ! -f "$DOMAIN_LIST_FILE" ]; then
    echo "Domain list file not found: $DOMAIN_LIST_FILE"
    exit 1
fi

# 从文件中读取域名到数组
DOMAINS=()
while IFS= read -r line || [ -n "$line" ]; do
    # 跳过空行和以 # 开头的注释行
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        DOMAINS+=("$line")
    fi
done < "$DOMAIN_LIST_FILE"

# 检查是否有域名被读取
if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "No domains found in $DOMAIN_LIST_FILE"
    exit 1
fi

# 遍历每个域名
for DOMAIN in "${DOMAINS[@]}"; do
    LIVE_DIR="/etc/letsencrypt/live/$DOMAIN"
    PEM_FILE="$LIVE_DIR/haproxy.pem"

    # 检查证书文件是否存在
    if [ -f "$LIVE_DIR/privkey.pem" ] && [ -f "$LIVE_DIR/fullchain.pem" ]; then
        echo "Processing domain: $DOMAIN"

        # 合并私钥和证书链
        cat "$LIVE_DIR/privkey.pem" "$LIVE_DIR/fullchain.pem" > "$PEM_FILE"

        # 设置权限
        chmod 600 "$PEM_FILE"
        chown haproxy:haproxy "$PEM_FILE"

        echo "PEM file created for $DOMAIN at $PEM_FILE"
    else
        echo "Certificate files not found for $DOMAIN in $LIVE_DIR"
    fi
done

# 重载 HAProxy
# echo "Reloading HAProxy service..."
# systemctl reload haproxy

echo "All domains processed successfully."