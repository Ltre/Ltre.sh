# h265.sh 的改进版，由两个参数减少到一个参数，并直接运行于后台，生成转码日志.
if [ -n "$1" ];then
    nohup ffmpeg -i "$1" -c:v libx265 -c:a copy -movflags +faststart "$1.mkv" >> "$1.log" &
    exit
else
    echo "缺少输入文件路径"
    exit
fi