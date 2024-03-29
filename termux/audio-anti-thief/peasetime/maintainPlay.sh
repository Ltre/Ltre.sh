# 在一些机型上无法使用mpv，报CANNOT LINK EXECUTABLE "mpv": cannot locate symbol "TIFFReadRGBAImage_2" referenced by "/system/lib64/libskia.so"...
# playbin=$PREFIX/bin/play-audio
playbin=$PREFIX/bin/mpv # 能用这个就用这个，这个有播放时间刻度显示


playAudio(){
    if [ "`ps aux|grep mpv|grep -wv grep|awk '{print $2}'`" ]; then
        return
    fi
    CUR_DIR=$(cd `dirname $0` && pwd -P)
    songpath=`ls ${CUR_DIR}/../audio/*.{m4a,webm,mp3,aac,wma} 2>/dev/null | sort -R | head -n1`
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
