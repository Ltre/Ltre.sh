# @todo 以后再做，通过termux-notification-list获取正在播放的歌曲，再执行远程操作
# 环境需求：
# 1、双方都已安装frpc并接入网络部署（stcp方式）
# 2、远程已配置SSHD
# 3、双方已安装rsync
# 4、客户机已安装sshpass
# 5、远程已安装mpv或play-audio

# 先rsync同步歌曲文件到远程机器
sshpass -p '对方机器SSH密码' rsync -av -e 'ssh -p 2091' /sdcard/存档/原机存档目录/音频整理/AlarmClock/AlarmClockPart6/ぷらそ にか\ -\ レオ\ \(cover\ 優里\).m4a abc@localhost:/data/data/com.termux/files/home/tmp/

# 再控制远程机器播放歌曲
sshpass -p '对方机器SSH密码' ssh -p2091 localhost "mpv ~/tmp/ぷらそ にか\ -\ レオ\ \(cover\ 優里\).m4a"
