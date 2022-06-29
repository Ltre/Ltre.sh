for pid in `ps -ef|grep rh265.sh|grep -vw grep|awk '{print $2}'`; do
	echo "================================"
	echo "PID: $pid"
	echo "    cwd: "`ls -l /proc/${pid}/cwd`
	echo "    cmdline: "`cat /proc/${pid}/cmdline`
	echo "    relate pids: "`ls /proc/${pid}/task`
	#echo "\t logfile maybe: "
	#echo "\t\t "`ls -l /proc/${pid}/cwd`/\*.out
	#echo "\t\t "`ls -l /proc/${pid}/cwd`/\*.nohup
done

servers=(gzz gz txhk aly mm webdev)
for serv in ${servers[@]}; do
    echo "------------- Server $serv --------------"
    CUR_DIR="$(dirname "$(readlink -f "$0")")"
    . "${CUR_DIR}"/conf/rh265.$serv.conf
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "echo 'FFMpeg进程数:' \`ps -ef|awk '{print \$8}'|grep ffmpeg|wc -l\`;  echo 'rsync进程数:' \`ps -ef|awk '{print \$8}'|grep rsync|wc -l\`"
done
