while true 
do
    #echo \[`date +%Y-%M-%D %H%m%S`\]
    echo 'waiting next volume for 60s...'
    sleep 75
    # date +%H%M%S
    if [ `date +%k` -ge 9 ] && [ `date +%k` -lt 23 ]; then
        termux-volume music $((6 + $RANDOM%5)) # 09:00~23:00 音量(6~10)/15
    elif [ `date +%k` -ge 23 ] && [ `date +%k` -ne 0 ]; then
	termux-volume music $((5 + $RANDOM%3)) # 23:00~00:00 音量(5-7)/15
    elif [ `date +%k` -ge 0 ] && [ `date +%k` -lt 2 ]; then
        termux-volume music $((3 + $RANDOM%3)) # 00:00~02:00 音量(3~5)/15
    else
        termux-volume music $((3 + $RANDOM%2)) # 02:00~09:00 音量(3-4)/15
    fi
done

