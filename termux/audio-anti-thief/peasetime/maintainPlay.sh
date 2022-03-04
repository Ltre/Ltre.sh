playAudio(){
    if [ "`ps aux|grep mpv|grep -wv grep|awk '{print $2}'`" ]; then
        return
    fi
    CUR_DIR=$(cd `dirname $0` && pwd -P)
    songpath=`ls ${CUR_DIR}/../audio/*.m4a | sort -R | head -n1`
    echo "Playing ..."
    echo "$songpath"
    mpv "$songpath"
}


stopAudio(){
    killall mpv # kill -9 `pgrep mpv`
}

pauseAudio(){
    kill -STOP `pgrep mpv`
}

resumeAudio(){
    kill -CONT `pgrep mpv`
}

while true
do
    if [ `date +%S` -ge 10 ] && [ `date +%S` -le 12 ]; then
        echo "Current volume of music: "`termux-volume|jq ".[3].volume"`;
    fi
    echo 'waiting next track for 2s...'
    sleep 2
    playAudio
done
