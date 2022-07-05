# 获取进程名称
pid2name(){
    local arr=(`ps -p $1 | grep -vw grep | awk 'NF{print $NF}'`)
    # 本来上一句直接再加个 【|tail -1】取最后一行(过滤掉CMD)即可，但是考虑到进程id不存在的情况，不得不写下此委屈的判断代码
    if [ ${#arr[@]} -lt 2 ]; then
        echo ''  # 找不到进程，输出空串便于代码识别
    else
        echo ${arr[@]} | awk 'NF{print $NF}'
    fi
}

# 获取父进程id
pid2ppid(){
    local pname=`pid2name $1`
    if [[ "$pname" = "" ]]; then
        echo 0  # 找不到进程，输出0便于代码识别
    else
        ps -ef | grep $1 | grep -vw grep | grep $pname | awk '{print $3}' | head -1
    fi
}

# 获取父进程名称
pid2paname(){
    local ppid=`pid2ppid $1`
    if [[ "$ppid" = "0" ]]; then
        echo ""  # 找不到进程，输出空串便于代码识别
    else
	pid2name $ppid
    fi
}

#echo pid2name `pid2name 3332`
#echo pid2ppid `pid2ppid 3332`
#echo pid2paname `pid2paname 3332`
#exit


for pid in `ps -ef|grep rh265|grep -vw grep|awk '{print $2}'`; do
        if [[ "`pid2name ${pid}`" = "`pid2paname ${pid}`" ]]; then
	    continue # 过滤掉重复的子进程（这个子进程是由于rh265.sh的主逻辑用花括号执行造成的）
	fi
	echo "================================"
	echo "PID: $pid, PPID: `pid2ppid ${pid}`, PPName: `pid2paname`"
	echo "    exe: `ps -p ${pid}|grep -vw grep|awk 'NF{print $NF}'|tail -1`"
	echo "    ppname: `pid2paname ${pid}`"
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
