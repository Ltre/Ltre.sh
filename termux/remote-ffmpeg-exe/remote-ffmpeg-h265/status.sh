#!/data/data/com.termux/files/usr/bin/bash


CUR_DIR="$(dirname "$(readlink -f "$0")")"
MONITOR_DIR="${CUR_DIR}"/logs/monitor
. "${CUR_DIR}"/lib/monitor.lib
mkdir -p "${CUR_DIR}"/cache


# status -t # 仅列出任务列表，不含机器状态
# status -s # 仅列出机器状态，不含任务列表
# status -p ${pid} # 仅列出某任务的信息 （此模式将不列出所有任务列表和机器状态）
# status -p ${pid} -c [sub_cmd] # 执行某任务的子指令 （此模式将不列出所有任务列表和机器状态）。[sub_cmd]子命令，支持cwd|CMD|local|localFull|remote|loging|logend|logRemote|state
HIDE_TASK=0
HIDE_SERV=0
TASK_PID=0
SUB_CMD=''
while getopts "stp:c:" optname; do
    case "$optname" in
        s)
            HIDE_TASK=1
            ;;
        t)
            HIDE_SERV=1
            ;;
        p)
            TASK_PID=$OPTARG
            HIDE_TASK=1
			HIDE_SERV=1
			;;
		c)
			SUB_CMD="${OPTARG}"
            ;;
        *)
            echo "error arg option: -${optname}."
            exit
            ;;
    esac
done


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





if [[ "${HIDE_TASK}" != "1" ]]; then

	for pid in `ps -ef|grep rh265|grep -vw grep|awk '{print $2}'`; do
		if [[ "`pid2name ${pid}`" = "`pid2paname ${pid}`" ]]; then
			continue # 过滤掉重复的子进程（这个子进程是由于rh265.sh的主逻辑用花括号执行造成的）
		fi
		ppname=`pid2paname ${pid}`; 
		if [[ "$paname" = "" ]];then 
			echo SYSTEM_HIDE; 
		else 
			echo $paname; 
		fi
		echo "================================"
		echo "PID: $pid, PPID: `pid2ppid ${pid}`, PPName: ${ppname}"
		echo "    exe: `ps -p ${pid}|grep -vw grep|awk 'NF{print $NF}'|tail -1`"
		echo "    ppname: ${ppname}"
		echo "    cwd: "`ls -l /proc/${pid}/cwd`
		echo "    relate pids: "`ls /proc/${pid}/task`
		monitor_get '.' "${MONITOR_DIR}/${pid}.json" | jq -r
		#echo "    cmdline: "`cat /proc/${pid}/cmdline`
		#echo "\t logfile maybe: "
		#echo "\t\t "`ls -l /proc/${pid}/cwd`/\*.out
		#echo "\t\t "`ls -l /proc/${pid}/cwd`/\*.nohup
	done

fi





if [[ "${HIDE_SERV}" != "1" ]]; then

	servers=(138 139 aly gz gzz mm txhk webdev)
	for serv in ${servers[@]}; do
		echo "------------- Server $serv --------------"
		CUR_DIR="$(dirname "$(readlink -f "$0")")"
		. "${CUR_DIR}"/conf/rh265.$serv.conf
		sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "echo 'FFMpeg进程数:' \`ps -ef|awk '{print \$8}'|grep ffmpeg|wc -l\`;  echo 'rsync进程数:' \`ps -ef|awk '{print \$8}'|grep rsync|wc -l\`"
	done

fi




# cwd|cmd|local|localfull|remote|loging|logend|logRemote|state
if [[ "${TASK_PID}" != "0" ]]; then

	case "${SUB_CMD}" in 
        serv|cwd|cmd|'local'|localfull|remote|state)
            monitor_get ".${SUB_CMD}" "${MONITOR_DIR}/${TASK_PID}.json" | jq -r
            ;;
        loging|logend)
            tail -f -n 100 "$(monitor_get ".${SUB_CMD}" "${MONITOR_DIR}/${TASK_PID}.json" | jq -r)"
            ;;
        logremote)
            monitor_get ".${SUB_CMD}" "${MONITOR_DIR}/${TASK_PID}.json" | jq -r > "${CUR_DIR}"/cache/${TASK_PID}.rlog.sh
            bash "${CUR_DIR}"/cache/${TASK_PID}.rlog.sh
            ;;
        *)
            monitor_get '.' "${MONITOR_DIR}/${TASK_PID}.json" | jq -r
            ;;
    esac
        
fi

