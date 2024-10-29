kill -9 `ps -ef|grep haproxy|grep '.cfg'|grep -v grep|awk '{print $2}'` 2>&1 > /dev/null
for i in $(ls /etc/haproxy/haproxy*.cfg); do
    haproxy -f "$i"
done
