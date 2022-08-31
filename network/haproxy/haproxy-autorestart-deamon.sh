# 跳板机跑了一堆haproxy，有时可能会因某些原因无法连接，需要定时重启
# 用此脚本可批量定时重启
# 建议配合pm2/supervisor使用，管理更方便有序

whenh=15 #凌晨5点重启
lock=0 #每日仅一次
loopgap=3000
today=`date +%Y%m%d`
nowh=`date +%k` #没有前导零的小时

while true; do
    if [ "$nowh" -ge "$whenh" ] && [ "$nowh" -lt "$((whenh+1))" ] && [ "$lock" != "$today" ]; then

        lock=$today
        kill -9 `ps -ef|grep haproxy|grep '.cfg'|grep -v grep|awk '{print $2}'` 2>&1 > /dev/null
        for i in $(ls /etc/haproxy/haproxy*.cfg); do
          haproxy -f "$i"
        done

    fi
    sleep $loopgap
done

