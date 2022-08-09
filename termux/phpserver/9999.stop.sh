kill -9 `ps -ef|grep php|grep 9999|grep -vw grep|awk '{print $2}'` 2>/dev/null
