#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# 接受第一个参数：本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".drct.mp4"]

VDNAME=$1 


CUR_DIR=$(cd `dirname $0` && pwd -P)
. "${CUR_DIR}"/rfmpg-drct.conf


# 上传
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}"
sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" "${VDNAME}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.inputvideo" 

# 远程转码  (todo: 如果突然断网怎么办？考虑服务端先nohup，并写文件标识，方便客户端查询转码状态)
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "ffmpeg -i ${REMOTEDIR}/${REMOTE_TMPFILE}.inputvideo ${REMOTEDIR}/${REMOTE_TMPFILE}.drct.mp4 "

# 取回前先改名，减少在审查方面的麻烦
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mv ${REMOTEDIR}/${REMOTE_TMPFILE}.drct.mp4 ${REMOTEDIR}/${REMOTE_TMPFILE}.outvideo"

# 取回结果
sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.outvideo"  "${VDNAME}.drct.mp4"

# 判断已下载后，删除服务器的缓存文件 （todo）