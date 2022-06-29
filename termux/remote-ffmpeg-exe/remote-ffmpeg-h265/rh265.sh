#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# @todo 断点续传失败，文件自动从0开始，需要仔细研究下rsync的相关参数
# @todo 需要dashboard跟踪每个任务的文件绝对路径、日志、状态。能识别是否因网络不稳定等原因导致某个循环代码僵住无法跳出


# 参数
#       接受最后一个参数，作为本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]  （此参数必须写在最尾）
#       -c 参数可定制 ffmpeg 的crf参数值 （可选）
#       -s 参数指定配置文件的简称，例如 -s mm 会指定 rh265.mm.conf  （可选）
ARGS=("$@")
VDNAME=${ARGS[$(($#-1))]}   # 输入文件名
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





# 根据选择的服务器，装载配置文件
CUR_DIR="$(dirname "$(readlink -f "$0")")"
. "${CUR_DIR}"/conf/rh265${SERV}.conf





# 本地生成文件统一用的完整中缀，如 ".mm.crf23"，生成某文件的具体名称为 xxxxxxx.mm.crf23.finished
GENF_SUFFIX=${SERV}${CRF_SUFFIX}    

# 生成PID标记文件，便于跟踪
PID_FILE="${VDNAME}"${GENF_SUFFIX}.pid.$$
touch "$PID_FILE"

# 准备好本地日志文件及归档目录
LOG_FILE="${CUR_DIR}"/logs/${REMOTE_TMPFILE}-pid-$$.log
LOG_FILE_END="${CUR_DIR}"/logs/end
mkdir -p "${LOG_FILE_END}"
echo "======== PID=$$ ======== 
    cwd: `ls -l /proc/$$/cwd`
    cmdline: `cat /proc/${pid}/cmdline`
    relate pids: `ls /proc/${pid}/task`
    local: $VDNAME
    remote: ${REMOTEDIR}/${REMOTE_TMPFILE}.input
" >> "${LOG_FILE_END}/log.map"

# 生成便于查看本地日志的脚本文件
LOG_SHOTCUT="${VDNAME}"${GENF_SUFFIX}.locallog.sh
echo "tail -f -n 100 '${LOG_FILE}' " > "$LOG_SHOTCUT"

# 生成便于查看远程日志的脚本文件（等开始转码时再写）
RMLOG_SHOTCUT="${VDNAME}${GENF_SUFFIX}.remotelog.sh"

# 控制错误输出
# exec 2>> "`getLogPPath`"





{ # <<<<<<<<<<<<<<<<< 主逻辑开始 <<<<<<<<<<<<<<<<<





    # 上传 
    echo "上传中... ${VDNAME}  =>  远程目录${REMOTEDIR}/${REMOTE_TMPFILE}.input"
    uploadTo(){
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}" # 创建远程目录
        sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" "${VDNAME}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input" # 上传  （注意，多个了P参数，支持断点续传）
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.input |awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5" # 上传后写md5
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5"  "${VDNAME}${GENF_SUFFIX}.input.md5" # 下载md5到本地用于验证
    }
    while true; do
        if [[ -e "${VDNAME}${GENF_SUFFIX}.input.md5" ]]; then
        
            if [[ $(cat "${VDNAME}${GENF_SUFFIX}.input.md5") = '' ]]; then
                echo "他妈的，这是一种极端情况，如果没有这一条拦截，就被混过去了。（以前无缘无故在远程没有input文件的情况下，直接跳到了第二步的ffmpeg命令去了！）"
                uploadTo
                continue
            fi
            
            if [[ $(cat "${VDNAME}${GENF_SUFFIX}.input.md5") = $(md5sum "${VDNAME}"|awk '{print $1}') ]]; then 
                echo "已确认完整上传: ${VDNAME}"
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
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "nohup sh -c 'ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.input -c:v libx265 -c:a copy $CRF -movflags +faststart ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv; md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk \"{print \\\$1}\" > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5; touch ${REMOTEDIR}/${REMOTE_TMPFILE}.finished' > ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup 2>&1 &"
    echo "sshpass -p '${PASSWD}' ssh -l $USER -p $PORT $HOST 'tail -f -n 100 ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup'; " > "${RMLOG_SHOTCUT}" # 提供一条看远程日志的命令





    # 检查转码是否完成（1、如果完成则在服务端写入标记文件*.finished; 2、下载*.finished标记文件到本地；3、当本地检测到*.finished文件时则确认转码完成）
    while true; do
        echo 'waiting for 30s ...'
        sleep 30
        # 获取远程结果文件的大小
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "ls -sh ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"  "${VDNAME}${GENF_SUFFIX}.output.size" > /dev/null 2>&1
        if [[ -e "${VDNAME}${GENF_SUFFIX}.output.size" ]]; then
            echo '进行中, 远程结果文件大小：'`cat "${VDNAME}${GENF_SUFFIX}.output.size"`
        fi
        # 检查是否完成
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.finished"  "${VDNAME}${GENF_SUFFIX}.finished" > /dev/null 2>&1
        if [[ -e "${VDNAME}${GENF_SUFFIX}.finished" ]]; then
            break
        fi
    done





    # 取回前先改名，减少在审查方面的麻烦
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mv ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv ${REMOTEDIR}/${REMOTE_TMPFILE}.output"





    # 下载会确认完整性，并最后清理垃圾
    dlPath="${VDNAME}${GENF_SUFFIX}.mkv"
    echo "转码完毕，开始下载结果...  ${USER}@${HOST}:${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5  => ${dlPath}.mkv "
    downloadResult(){
        sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output"  "${dlPath}"  # 注意，多个了P参数，支持断点续传
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5"  "${VDNAME}${GENF_SUFFIX}.output.md5"
    }
    while true; do
        if [[ -e "${dlPath}" ]]; then
            if [[ $(cat "${VDNAME}${GENF_SUFFIX}.output.md5") = $(md5sum "${dlPath}"|awk '{print $1}') ]]; then 
                echo D
                # 确认已下载，开始清理垃圾
                sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST " rm ${REMOTEDIR}/${REMOTE_TMPFILE}.input  ${REMOTEDIR}/${REMOTE_TMPFILE}.output  ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size -f"
                rm "${VDNAME}${GENF_SUFFIX}.input.md5" "${VDNAME}${GENF_SUFFIX}.output.md5" "${VDNAME}${GENF_SUFFIX}.output.size" "${VDNAME}${GENF_SUFFIX}.finished" -f
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