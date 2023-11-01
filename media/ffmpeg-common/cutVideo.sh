# 可用双引号/单引号括起来的空串表示参数缺省

SS=""
if [ -n "$2" ]; then
    SS=" -ss $2 "
fi

TO=""
if [ -n "$3" ]; then
    TO=" -to $3 "
fi

echo "1: $1"
echo "2: $2"
echo "3: $3"

echo "SS: $SS"
echo "TO: $TO"


if [ -n "$1" ];then
    ffmpeg $SS $TO -i "$1" -c copy -movflags +faststart "${1%.*}-cut.mp4"
else
    echo "Tip: cutVideo input.mp4 '00:01:05' '01:02:03'"
    exit
fi
