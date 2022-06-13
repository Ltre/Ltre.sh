#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# 接受第一个参数：本地视频文件路径，转码完成后的结果文件为 [输入路径再追加".mkv"]

VDNAME=$1  

REMOTEDIR="~/tmp/termux-ffmpeg-remote"
PASSWD='密码'
PORT=端口
HOST="服务器地址"
USER=用户名

REMOTE_TMPFILE=`date +%Y%m%d-%H%M%S`

# 上传
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "mkdir -p ${REMOTEDIR}"
sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" "${VDNAME}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.inputvideo" 

# 远程转码
sshpass -p "${PASSWD}" ssh -l $USER -p $PORT $HOST "~/tmp/bilibili/h265r30.sh  ${REMOTEDIR}/${REMOTE_TMPFILE}.inputvideo  ${REMOTEDIR}/${REMOTE_TMPFILE}.mkv "

# 取回结果
sshpass -p "${PASSWD}" rsync -av -e "ssh -p ${PORT}" ${USER}@${HOST}:"${REMOTEDIR}/${REMOTE_TMPFILE}.mkv"  "${VDNAME}.mkv"

