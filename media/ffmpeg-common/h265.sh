# e.g. ~/bin/h265 "/storage/emulated/0/Movies/NewPipe/野郎猫 - 一只肥猫紧紧抓住一根木棍并尝试跳钢管舞.mp4" "/storage/emulated/0/Movies/NewPipe/野郎猫 - 一只肥猫紧紧抓住一根木 棍并尝试跳钢管舞.mkv" 33 1280:270 25 '01:01' '02:02'
# 可用双引号/单引号括起来的空串表示参数缺省

CRF=""
if [ -n "$3" ]; then
    CRF=" -crf $3 "
fi

SCL=""
if [ -n "$4" ]; then
    SCL=" -vf scale=$4 "
fi

R=""
if [ -n "$5" ]; then
    R=" -r $5 "
fi

SSTO=""
if [ -n "$6" ]; then
    SSTO=" -ss $6 "
fi
if [ -n "$7" ]; then
    SSTO=$SSTO" -to $7 "
fi

echo "1: $1"
echo "2: $2"
echo "3: $3"
echo "4: $4"
echo "5: $5"
echo "6: $6"
echo "7: $7"

echo "CRF  : $CRF"
echo "SCL  : $SCL"
echo "R    : $R"
echo "SSTO : $SSTO"


if [ -n "$1" ];then
    if [ -n "$2" ];then
        ffmpeg $SSTO -i "$1" -c:v libx265 $SCL $R $CRF -c:a copy -movflags +faststart "$2"
        exit
    else
        echo "缺少输出文件路径"
        exit
    fi
else
    echo "缺少输入文件路径"
    echo "Tip: h265 input.mp4 output.mkv CRF(28) SCL(1280:720) R(30) '00:01:05' '01:02:03'"
    exit
fi
