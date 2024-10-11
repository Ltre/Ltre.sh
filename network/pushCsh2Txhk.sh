# 用于发布订阅链接，不能直接使用
HOST=x-aa-bb.adb.com
PORT=8999
LOCALPATH=/sdcard/Download/Sync/工作空间专用/FQ/ccc.txt
REMOTEPATH=/home/wwwroot/ccc.adb.com/ccc/dontcopycccname.txt
PASS=`cat ~/pehz/shs`
sshpass -p "$PASS" rsync -avP -e "ssh -p ${PORT}"  "${LOCALPATH}"  root@${HOST}:"${REMOTEPATH}"
