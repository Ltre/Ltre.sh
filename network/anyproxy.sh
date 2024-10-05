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
    pip3)
        shift
        pip3 --proxy=$proxy "$@"
        ;;
    npm)
        shift
        npm --proxy=$proxy "$@"
        ;;
    composer)
        shift
        composer config -g repositories.packagist composer $proxy
        composer "$@"
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
    rails)
        shift
        rails new myapp --skip-bundle
        cd myapp
        bundle config set --local mirror.https://rubygems.org $proxy
        bundle install
        ;;
    flutter)
        shift
        flutter pub get --proxy=$proxy
        ;;
    mvn)
        shift
        mvn -Dproxy.host=127.0.0.1 -Dproxy.port=1080 "$@"
        ;;
    lein)
        shift
        lein with-proxy "$@"
        ;;
    go)
        shift
        GOPROXY=$proxy go "$@"
        ;;
    yarn)
        shift
        yarn config set proxy $proxy
        yarn "$@"
        ;;
    brew)
        shift
        HOMEBREW_PROXY=$proxy brew "$@"
        ;;
    pkg)
        shift
        pkg install --proxy=$proxy "$@"
        ;;
    ftp)
        shift
        ftp -p -o "http_proxy=$proxy" "$@"
        ;;
    curlftpfs)
        shift
        curlftpfs -o "proxy=$proxy" "$@"
        ;;
    httpie)
        shift
        http --proxy=$proxy "$@"
        ;;
    mtr)
        shift
        mtr --proxy=$proxy "$@"
        ;;
    ssh)
        shift
        ssh -o ProxyCommand='nc -x 127.0.0.1:1080 %h %p' "$@"
        ;;
    socat)
        shift
        socat - SOCKS5:127.0.0.1:$@ 
        ;;
    gpg)
        shift
        gpg --keyserver hkp://keyserver.ubuntu.com:80 --proxy=$proxy "$@"
        ;;
    *)
        echo "Unsupported command: $1"
        exit 1
        ;;
esac
