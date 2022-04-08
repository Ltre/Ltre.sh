while true 
do
    #echo \[`date +%Y-%M-%D %H%m%S`\]
    echo 'waiting next volume for 60s...'
    sleep 75
    # date +%H%M%S
    if [ `date +%k` -ge 9 ] && [ `date +%k` -lt 22 ]; then
        termux-volume music $((6 + $RANDOM%4)) # 09:00~22:00 音量(6~9)/15
    elif [ `date +%k` -ge 22 ] && [ `date +%k` -ne 0 ]; then
	termux-volume music $((5 + $RANDOM%3)) # 22:00~00:00 音量(5-7)/15
    elif [ `date +%k` -ge 0 ] && [ `date +%k` -lt 2 ]; then
        termux-volume music $((3 + $RANDOM%3)) # 00:00~02:00 音量(3~5)/15
    else
        termux-volume music $((2 + $RANDOM%4)) # 02:00~09:00 音量(2-4)/15
    fi


    #让音响找个时间休息下（逻辑暂时放这里）
    if [ $(($RANDOM%300)) -eq 1 ]; then
        kill -STOP `pgrep mpv`
	sleep 60
	kill -CONT `pgrep mpv`
    fi
    
    
    # 电量警告
    minu=$((`date +%M`%10))
    if [ ${minu#0} -eq 8 ]; then
        tbsJson=`termux-battery-status`
        tbsPerc=`echo $tbsJson|jq ".percentage"`
        tbsPlgd=`echo $tbsJson|jq ".plugged"`
        # alert-remote放在Ltre.sh/termux/p10-plugins/start-remote.sh.zip 
        # 如果日后在迁移过程中因缺失文件等原因报错，可删除此句
        if [ $tbsPerc -le 30 ] && [ $tbsPlgd = \"UNPLUGGED\" ]; then
            echo "p10-termux-alert%20电量不足，尽快充电（"${tbsPerc}"）!"
            . ~/mydir/bin/alert-remote.sh "p10-termux-alert%20电量不足，尽快充电（"${tbsPerc}"）!"
        # else
        #   echo "p10-termux-alert%20电量充足（"${tbsPerc}"）!"
        #   . ~/mydir/bin/alert-remote.sh "p10-termux-alert%20电量充足（"${tbsPerc}"）!"
        fi
    fi
    
done

