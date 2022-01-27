
playAudio(){
    songpath=`ls /data/data/com.termux/files/home/mydir/bin/audio-anti-thief/audio/*.m4a | sort -R | head -n1`
    echo "Playing ..."
    echo $songpath
    mpv "$songpath"
}


stopAudio(){
    killall mpv # kill -9 `pgrep mpv`
}


while true
do
    echo 'waiting next track for 2s...'
    sleep 2
    playAudio
done
