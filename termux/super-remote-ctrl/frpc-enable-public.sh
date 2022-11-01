# 启动frpc进程常驻，不含敏感信息
frpcPID=`ps -ef|grep frpc.ini|grep -v grep|awk '{print $2}'`
if [ "$frpcPID" = "" ]; then
    nohup ~/bin/frp/frpc -c ~/bin/frp/conf/frpc.ini >> ~/bin/frp/frpc.log &
fi

termux-wake-lock #还是要叫醒，否则可能会断掉SSH
sshd
