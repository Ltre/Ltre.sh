#!/bin/bash

# 设置软链(linux vps)：ln -s ~/mydir/bin/anyproxy.sh /usr/local/bin/anyproxy
# 设置软链(termux)：ln -s ~/bin/anyproxy.sh /data/data/com.termux/files/usr/bin/anyproxy

# 使用： anyproxy curl google.com

# 使用socks5代理的地址
proxy="socks5h://127.0.0.1:1080"

# 根据传入的命令判断并使用代理
case "$1" in
    curl)
        shift
        curl -x $proxy "$@"
        ;;
    wget)
        shift
        wget --proxy=on --execute="http_proxy=$proxy" "$@"
        ;;
    git)
        shift
        git -c http.proxy=$proxy "$@"
        ;;
    pip)
        shift
        pip --proxy=$proxy "$@"
        ;;
    npm)
        shift
        npm --proxy=$proxy "$@"
        ;;
    apt-get)
        shift
        apt-get -o Acquire::http::Proxy=$proxy "$@"
        ;;
    yum)
        shift
        yum --setopt=proxy=$proxy "$@"
        ;;
    dnf)
        shift
        dnf --setopt=proxy=$proxy "$@"
        ;;
    rsync)
        shift
        rsync -e "ssh -o ProxyCommand='nc -x 127.0.0.1:1080 %h %p'" "$@"
        ;;
    scp)
        shift
        scp -o "ProxyCommand=nc -x 127.0.0.1:1080 %h %p" "$@"
        ;;
    sftp)
        shift
        sftp -o "ProxyCommand=nc -x 127.0.0.1:1080 %h %p" "$@"
        ;;
    *)
        echo "Unsupported command: $1"
        exit 1
        ;;
esac
