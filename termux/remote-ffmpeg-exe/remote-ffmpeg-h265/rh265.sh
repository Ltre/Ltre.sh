#!/data/data/com.termux/files/usr/bin/bash

#todo 断点续传失败，需要处理


# 远程ffmpeg转码
# 接受第一个参数：本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]

VDNAME=$1 


CUR_DIR=$(cd `dirname $0` && pwd -P)
. "${CUR_DIR}"/rh265.conf


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
            echo A
            break  # 确保完整上传后，才可跳出重试的循环
        else
            echo B
            uploadTo
        fi
    else
        echo C
        uploadTo
    fi
    sleep 1
done


echo '上传完毕，即将开始转码...'


# 后台远程转码
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "nohup sh -c 'ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.input -c:v libx265 -c:a copy -movflags +faststart ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv; md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv|awk \"{print \\\$1}\" > ${REMOTEDIR}/${REMOTE_TMPFILE}.output.md5; touch ${REMOTEDIR}/${REMOTE_TMPFILE}.finished' > ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup 2>&1 &"


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
            break
        else
            downloadResult
        fi
    else
        downloadResult
    fi
    sleep 1
done
