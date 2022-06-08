#!/data/data/com.termux/files/usr/bin/bash

# 远程ffmpeg转码
# 已对敏感参数打码

#要去除 .mp4 后缀
VDNAME=$1 

~/bin/rsync-to.sh 域名 端口 "$VDNAME" "~/tmp"
sshpass -p '密码' ssh -l用户 -p端口 域名 "~/tmp/bilibili/h265r30.sh ~/tmp/'${VDNAME}.mp4' ~/tmp/'${VDNAME}.mkv' "
~/bin/rsync-from.sh 域名 端口 "~/tmp/${VDNAME}.mkv" .

