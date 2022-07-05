#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# @todo 断点续传失败，文件自动从0开始，需要仔细研究下rsync的相关参数
# @todo 需要dashboard跟踪每个任务的文件绝对路径、日志、状态。能识别是否因网络不稳定等原因导致某个循环代码僵住无法跳出

CUR_DIR="$(dirname "$(readlink -f "$0")")"

# 参数
#       接受最后一个参数，作为本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]  （此参数必须写在最尾）
#       -c 参数可定制 ffmpeg 的crf参数值 （可选）
#       -s 参数指定配置文件的简称，例如 -s mm 会指定 rh265.mm.conf  （可选）
ARGS=("$@")
if [[ $# = 0 ]]; then less "${CUR_DIR}/readme.md"; exit; fi
VDPATH=${ARGS[$(($#-1))]}   # 输入文件名
CRF=""                      # ffmpeg命令的crf残片
CRF_SUFFIX=""               # 本地生成文件名后缀的crf部分
SERV=""                     # 带有服务器简称的文件名中缀残片
while getopts "c:s:" optname; do
    case "$optname" in
        c)
            CRF="-crf ${OPTARG}"
            CRF_SUFFIX=".crf${OPTARG}"
            ;;
        s)
            SERV=".${OPTARG}"
            ;;
        *)
            echo 'error arg option: -${optname}.'
            exit
            ;;
    esac
done





# 参数拦截
if ! [[ -e "${VDPATH}" ]]; then 
    echo "错误：输入的文件不存在"
    exit
fi





# 根据选择的服务器，装载配置文件
conf="${CUR_DIR}"/conf/rh265${SERV}.conf
if ! [[ -e "$conf" ]]; then 
    echo '配置文件 ${conf} 不存在.'
    exit
fi
. $conf





# 本地生成文件统一用的完整中缀，如 ".mm.crf23"，生成某文件的具体名称为 xxxxxxx.mm.crf23.finished
GENF_SUFFIX=${SERV}${CRF_SUFFIX}    

# 生成PID标记文件，便于跟踪
PID_FILE="${VDPATH}"${GENF_SUFFIX}.pid.$$
touch "$PID_FILE"

# 准备好本地日志文件及归档目录
LOG_FILE="${CUR_DIR}"/logs/${REMOTE_TMPFILE}-pid-$$.log
LOG_FILE_END="${CUR_DIR}"/logs/end
mkdir -p "${LOG_FILE_END}"
echo "======== PID=$$ ======== 
    cwd: `ls -l /proc/$$/cwd`
    cmdline: `cat /proc/$$/cmdline`
    relate pids: `ls /proc/$$/task`
    local: $VDPATH
    remote: ${REMOTEDIR}/${REMOTE_TMPFILE}.input
    log-ing: ${CUR_DIR}/logs/${REMOTE_TMPFILE}-pid-$$.log
    log-end: ${CUR_DIR}/logs/end/${REMOTE_TMPFILE}-pid-$$.log
    log-remote: sshpass -p '${PASSWD}' ssh -l $USER -p $PORT $HOST 'tail -f -n 100 ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup'
" >> "${LOG_FILE_END}/log.map"

# 生成便于查看本地日志的脚本文件
LOG_SHOTCUT="${VDPATH}"${GENF_SUFFIX}.locallog.sh
echo "tail -f -n 100 '${LOG_FILE}' " > "$LOG_SHOTCUT"

# 生成便于查看远程日志的脚本文件（等开始转码时再写）
RMLOG_SHOTCUT="${VDPATH}${GENF_SUFFIX}.remotelog.sh"

# 控制错误输出
# exec 2>> "`getLogPPath`"





{ # <<<<<<<<<<<<<<<<< 主逻辑开始 <<<<<<<<<<<<<<<<<





    # 上传 
    echo "上传中... ${VDPATH}  =>  远程目录${REMOTEDIR}/${REMOTE_TMPFILE}.input"
    uploadTo(){
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}" # 创建远程目录
        sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" "${VDPATH}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input" # 上传  （注意，多个了P参数，支持断点续传）
        #if [[ "no input" = $(sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "if ! [[ -e ${REMOTEDIR}/${REMOTE_TMPFILE}.input ]]; then echo 'no input'; else echo 'uploaded'; fi") ]]; then
        #    return 0  # 暂时不需要这个判断，有下方的input.md5有效性检测足矣
        #fi
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.input |awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5" # 上传后写md5
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5"  "${VDPATH}${GENF_SUFFIX}.input.md5" # 下载md5到本地用于验证
        # return 1
    }
    while true; do
        if [[ -e "${VDPATH}${GENF_SUFFIX}.input.md5" ]]; then
        
            if [[ $(cat "${VDPATH}${GENF_SUFFIX}.input.md5") = '' ]]; then
                echo "检测到远程无效的input.md5文件，可能rsync上传被中断，现在重试）"
                uploadTo
                continue
            fi
            
            if [[ $(cat "${VDPATH}${GENF_SUFFIX}.input.md5") = $(md5sum "${VDPATH}"|awk '{print $1}') ]]; then 
                echo "已确认完整上传: ${VDPATH}"
                break  # 确保完整上传后，才可跳出重试的循环
            else
                echo "上传失败，现在重试..."
                uploadTo
            fi
        else
            echo C
            uploadTo
        fi
        sleep 1
    done





    # 后台远程转码  @todo: 一定要确保网络不稳定时，正确完整执行（观察到的情况：在服务器准备转码时，提示input文件不存在。不知道是怎么到这一步的）
    echo '上传完毕，开始转码...'
    RM_COUNT=0
    tracingTranscode(){
        pnlist=$(sshpass -p "$PASSWD" ssh -l $USER -p $PORT $HOST "ps -ef|grep '${REMOTE_TMPFILE}'|grep ffmpeg|grep -vw grep|awk '{print \$8}'")
        for pn in $pnlist; do
            if [[ "$pn" = "ffmpeg" ]]; then
                return 1
            fi
        done
        #检测不到ffmpeg进程，可能视频文件太小，ffmpeg快速完成了，那么检测mkv文件是否存在
        remoteMkvFileExists=$(sshpass -p "$PASSWD" ssh -l $USER -p $PORT $HOST "if [[ -e ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv ]]; then echo 1; else echo 2; fi")
        if [[ 1 -eq "$remoteOutputFileExists" ]]; then
            return 1
        fi
        #进程和文件都找不到，
        return 0
    }
    while [ $RM_COUNT -lt 3 ]; do
        RM_COUNT=$((RM_COUNT+1))
        echo "第${RM_COUNT}次提交转码命令.."
		sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "nohup sh -c 'ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.input -c:v libx265 -c:a copy $CRF -movflags +faststart ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv; md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk \"{print \\\$1}\" > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5; touch ${REMOTEDIR}/${REMOTE_TMPFILE}.finished' > ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup 2>&1 &"
        
        TRACE_NUM=0
        while [ $TRACE_NUM -lt 6 ]; do
            TRACE_NUM=$((TRACE_NUM+1))
            tracingTranscode
            if [[ $? -eq 1 ]]; then
                echo "已确认成功提交转码命令，现进入循环等待阶段..."
                break 2;
            fi
            echo "无法确认是否完整提交转码命令，可能网络不稳定，现等待10秒后再次检查（第${RM_COUNT}轮/第${TRACE_NUM}次）"
            sleep 10
        done
    done

    if [ $RM_COUNT -ge 3 ]; then
        echo "三次机会提交命令结果均失败，程序被迫中止，请自行清理垃圾文件"
        exit
    fi
    echo "sshpass -p '${PASSWD}' ssh -l $USER -p $PORT $HOST 'tail -f -n 100 ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup'; " > "${RMLOG_SHOTCUT}" # 提供一条看远程日志的命令





    # 检查转码是否完成（1、如果完成则在服务端写入标记文件*.finished; 2、下载*.finished标记文件到本地；3、当本地检测到*.finished文件时则确认转码完成）
    while true; do
        echo 'waiting for 30s ...'
        sleep 30
        # 获取远程结果文件的大小
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "ls -sh ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"  "${VDPATH}${GENF_SUFFIX}.output.size" > /dev/null 2>&1
        if [[ -e "${VDPATH}${GENF_SUFFIX}.output.size" ]]; then
            echo '进行中, 远程结果文件大小：'`cat "${VDPATH}${GENF_SUFFIX}.output.size"`
        fi
        # 检查是否完成
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.finished"  "${VDPATH}${GENF_SUFFIX}.finished" > /dev/null 2>&1
        if [[ -e "${VDPATH}${GENF_SUFFIX}.finished" ]]; then
            break
        fi
    done





    # 取回前先改名，减少在审查方面的麻烦
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mv ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv ${REMOTEDIR}/${REMOTE_TMPFILE}.output"





    # 下载会确认完整性，并最后清理垃圾
    dlPath="${VDPATH}${GENF_SUFFIX}.mkv"
    echo "转码完毕，开始下载结果...  ${USER}@${HOST}:${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5  => ${dlPath} "
    downloadResult(){
        sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output"  "${dlPath}"  # 注意，多个了P参数，支持断点续传
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5"  "${VDPATH}${GENF_SUFFIX}.output.md5"
    }
    while true; do
        if [[ -e "${dlPath}" ]]; then
            if [[ $(cat "${VDPATH}${GENF_SUFFIX}.output.md5") = $(md5sum "${dlPath}"|awk '{print $1}') ]]; then 
                echo D
                # 确认已下载，开始清理垃圾
                sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST " rm ${REMOTEDIR}/${REMOTE_TMPFILE}.input  ${REMOTEDIR}/${REMOTE_TMPFILE}.output  ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size -f"
                rm "${VDPATH}${GENF_SUFFIX}.input.md5" "${VDPATH}${GENF_SUFFIX}.output.md5" "${VDPATH}${GENF_SUFFIX}.output.size" "${VDPATH}${GENF_SUFFIX}.finished" -f
                echo "取回完毕： ${dlPath}"
                break
            else
                downloadResult
            fi
        else
            downloadResult
        fi
        sleep 30
        echo '临时改的代码，下载的重试循环也等30秒，防止在户外网络不稳定时频繁下载浪费流量'
    done





} 2>&1 | tee -a "${LOG_FILE}" # >>>>>>>>>>>>>>> 主逻辑结束 >>>>>>>>>>>>>>>


# 结束时，清理PID和日志捷径；并将日志归档
rm -f "$PID_FILE"
rm -f "$LOG_SHOTCUT"
rm -f "$RMLOG_SHOTCUT"
mv  "${LOG_FILE}"  "${LOG_FILE_END}"