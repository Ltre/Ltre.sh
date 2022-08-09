# 一个9999端口的服务器，支持任意php，最初用于支持从外部命令（需加入 ~/.bashrc ）

CUR_DIR="$(dirname "$(readlink -f "$0")")"
if [ `ps -ef|grep php|grep 9999|grep -vw grep|wc -l` -eq 0 ]; then
    nohup php -S 0.0.0.0:9999 -t "$CUR_DIR" 2>&1 >> "${CUR_DIR}/"9999.daemon.log &
fi

