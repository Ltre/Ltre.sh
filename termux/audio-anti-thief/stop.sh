kill -9 `ps -ef |grep mpv|grep -wv grep|awk '{print $3}'`

# 仅在 nohup ./maintainPlay 时有效，所以上一句效果更强
kill -9 `ps -ef |grep maintainPlay|grep -wv grep|awk '{print $2}'`

# 父进程maintainPlay死了，但是mpv不会自觉停止
killall mpv

kill -9 `ps -ef |grep maintainVolume|grep -wv grep|awk '{print $2}'`
