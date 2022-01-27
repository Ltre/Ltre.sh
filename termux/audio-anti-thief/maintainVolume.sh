while true 
do
    #echo \[`date +%Y-%M-%D %H%m%S`\]
    echo 'waiting next volume for 60s...'
    sleep 60
    # date +%H%M%S
    if [ `date +%k` -ge 8 ] && [ `date +%k` -lt 23 ]; then
        termux-volume music $((8 + $RANDOM%4)) # 08:00~23:00 音量(8~11)/15
    elif [ `date +%k` -ge 23 ] && [ `date +%k` -ne 0 ]; then
        termux-volume music 8 # 23:00~00:00 音量8/15
    elif [ `date +%k` -ge 0 ] && [ `date +%k` -lt 2 ]; then
        termux-volume music $((6 + $RANDOM%3)) # 00:00~02:00 音量(6~8)/15
    else
        termux-volume music $((5 + $RANDOM%3)) # 02:00~08:00 音量(5~7)/15
    fi
done

