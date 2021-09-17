if [ -n "$1" ];then
    if [ -n "$2" ];then
        ffmpeg -i $1 -c:v libx265 -crf 20 -c:a copy  $2
        exit
    else
        echo "缺少输出文件路径"
        exit
    fi
else
    echo "缺少输入文件路径"
    exit
fi
