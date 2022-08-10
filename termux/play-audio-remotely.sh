# ./play-audio-remotely $host $port $path.m4a

# @todo 以后再做，通过termux-notification-list获取正在播放的歌曲，再执行远程操作
# 环境需求：
# 1、双方都已安装frpc并接入网络部署（stcp方式）
# 2、远程已配置SSHD
# 3、双方已安装rsync
# 4、客户机已安装sshpass
# 5、远程已安装mpv或play-audio

USR='用户'
PWD='密码'
HOST=$1
PORT=$2
AUDIO=$3
RMDIR='~/tmp/playaudio'
TMPFILE=`date +%Y%m%d-%H%M%S`-$((RANDOM%10000))

if [[ "$HOST" = '' ]]; then
    echo 'empty HOST'
    exit
fi

if [[ "$PORT" = '' ]]; then
    echo 'empty PORT'
    exit
fi

if [[ "$AUDIO" = '' ]]; then
    echo 'empty AUDIO'
    exit
fi

if ! [ -e "$AUDIO" ]; then
    echo 'AUDIO file is not found'
    exit
fi

sshpass -p "$PWD" ssh -l $USR -p $PORT $HOST "mkdir -p ${RMDIR}"

sshpass -p "$PWD" rsync -av -e "ssh -p ${PORT}" "${AUDIO}" ${USR}@${HOST}:"${RMDIR}/${TMPFILE}"

if [ "$?" != "0" ]; then
    echo 'rsync fail'
    exit
fi

sshpass -p "$PWD" ssh -l $USR -p $PORT $HOST "mpv ${RMDIR}/${TMPFILE}; rm -f ${RMDIR}/${TMPFILE}"

