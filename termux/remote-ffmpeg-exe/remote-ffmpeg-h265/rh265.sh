#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# @todo 断点续传失败，文件自动从0开始，需要仔细研究下rsync的相关参数





# 参数
#       接受最后一个参数，作为本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]  （此参数必须写在最尾）
#       -c 参数可定制 ffmpeg 的crf参数值 （可选）
#       -s 参数指定配置文件的简称，例如 -serv mm 会指定 rh265.mm.conf  （可选）
ARGS=("$@")
VDNAME=${ARGS[$(($#-1))]}
CRF=""
SERV=""
while getopts "c:s:" optname; do
    case "$optname" in
        c)
            CRF="-crf ${OPTARG}"
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





# 装载配置文件
CUR_DIR=$(cd `dirname $0` && pwd -P)
. "${CUR_DIR}"/rh265${SERV}.conf





# 上传 
echo "上传中... ${VDNAME}  =>  远程目录${REMOTEDIR}/${REMOTE_TMPFILE}.input"
uploadTo(){
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}" # 创建远程目录
    sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" "${VDNAME}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input"  # 上传  （注意，多个了P参数，支持断点续传）
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.input |awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5" # 上传后写md5
    sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5"  "${VDNAME}.input.md5" # 下载md5到本地用于验证
}
while true; do
    if [[ -e "${VDNAME}.input.md5" ]]; then
        if [[ $(cat "${VDNAME}.input.md5") = $(md5sum "${VDNAME}"|awk '{print $1}') ]]; then 
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





# 后台远程转码
echo '上传完毕，开始转码...'
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "nohup sh -c 'ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.input -c:v libx265 -c:a copy $CRF -movflags +faststart ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv; md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk \"{print \\\$1}\" > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5; touch ${REMOTEDIR}/${REMOTE_TMPFILE}.finished' > ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup 2>&1 &"





# 检查转码是否完成（1、如果完成则在服务端写入标记文件*.finished; 2、下载*.finished标记文件到本地；3、当本地检测到*.finished文件时则确认转码完成）
while true; do
    echo 'waiting for 30s ...'
    sleep 30
    # 获取远程结果文件的大小
    sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "ls -sh ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"
    sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.size"  "${VDNAME}.output.size" > /dev/null 2>&1
    if [[ -e "${VDNAME}.output.size" ]]; then
        echo '进行中, 远程结果文件大小：'`cat "${VDNAME}.output.size"`
    fi
    # 检查是否完成
    sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.finished"  "${VDNAME}.finished" > /dev/null 2>&1
    if [[ -e "${VDNAME}.finished" ]]; then
        break
    fi
done





# 取回前先改名，减少在审查方面的麻烦
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mv ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv ${REMOTEDIR}/${REMOTE_TMPFILE}.output"





echo '转码完毕，开始下载结果...'





# 下载会确认完整性，并最后清理垃圾
downloadResult(){
    sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output"  "${VDNAME}.mkv"  # 注意，多个了P参数，支持断点续传
    sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5"  "${VDNAME}.output.md5"
}
while true; do
    if [[ -e "${VDNAME}.mkv" ]]; then
        if [[ $(cat "${VDNAME}.output.md5") = $(md5sum "${VDNAME}.mkv"|awk '{print $1}') ]]; then 
            echo D
            # 确认已下载，开始清理垃圾
            sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST " rm ${REMOTEDIR}/${REMOTE_TMPFILE}.input  ${REMOTEDIR}/${REMOTE_TMPFILE}.output  ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5  ${REMOTEDIR}/${REMOTE_TMPFILE}.output.size -f"
            rm "${VDNAME}.input.md5" "${VDNAME}.output.md5" "${VDNAME}.output.size" "${VDNAME}.finished" -f
            echo "取回完毕： ${VDNAME}.mkv"
            break
        else
            downloadResult
        fi
    else
        downloadResult
    fi
    sleep 120
    echo '临时改的代码，下载的重试循环也等120秒，防止在户外网络不稳定时频繁下载浪费流量'
done
