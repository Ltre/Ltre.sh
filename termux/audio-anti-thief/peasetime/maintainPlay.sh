
playAudio(){
    CUR_DIR=$(cd `dirname $0` && pwd -P)
    songpath=`ls ${CUR_DIR}/../audio/*.m4a | sort -R | head -n1`
    echo "Playing ..."
    echo $songpath
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
    echo 'waiting next track for 2s...'
    sleep 2
    playAudio
done
