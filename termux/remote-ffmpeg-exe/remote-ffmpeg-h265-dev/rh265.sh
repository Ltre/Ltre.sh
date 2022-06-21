#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# 接受第一个参数：本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]

VDNAME=$1 


CUR_DIR=$(cd `dirname $0` && pwd -P)
. "${CUR_DIR}"/rh265.conf


# 上传 
while true; do
    echo "上传中... ${VDNAME}  =>  远程目录${REMOTEDIR}/${REMOTE_TMPFILE}.input"
    if [[ -e "${VDNAME}.input.md5" ]]; then
        if [[ $(cat "${VDNAME}.input.md5") = $(md5sum "${VDNAME}"|awk '{print $1}') ]]; then 
            echo A
            break  # 确保完整上传后，才可跳出重试的循环
        else
            echo B
        fi
    else
        echo C
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}" # 创建远程目录
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" "${VDNAME}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input"  # 上传
        sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "md5sum ${REMOTEDIR}/${REMOTE_TMPFILE}.input |awk '{print \$1}' > ${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5" # 上传后写md5
        sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.input.md5"  "${VDNAME}.input.md5" # 下载md5到本地用于验证
    fi
    sleep 1
done


echo '上传完毕，即将开始转码...'


# 后台远程转码
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "nohup sh -c 'ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.input -c:v libx265 -c:a copy -movflags +faststart ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv; touch ${REMOTEDIR}/${REMOTE_TMPFILE}.finished' > ${REMOTEDIR}/${REMOTE_TMPFILE}.nohup 2>&1 &"


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


# todo: 考虑对下载过程进行重试，提高可用性

# 取回前先改名，减少在审查方面的麻烦
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mv ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv ${REMOTEDIR}/${REMOTE_TMPFILE}.output"

# 取回结果  (@todo: 如果下载过程中网络不稳定，如何处理？这个必须处理，因为不确定何时开始下载)
sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.output"  "${VDNAME}.mkv"

# 判断已下载后，删除服务器的缓存文件 @todo: 应该确保大小与服务器完全一致后再清理
# if [[ -e "${VDNAME}.mkv" ]]; then
#     sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "rm '${REMOTEDIR}/${REMOTE_TMPFILE}.input' -f; rm '${REMOTEDIR}/${REMOTE_TMPFILE}.output' -f"
# fi
