# 合并B站缓存或youtubedr下载的音频和视频
F1=$1
F2=$2
OUTF=$3
if [[ "$OUTF" == "" ]]; then
    OUTF=merge.mp4
fi

ffmpeg -i "$F1" -i "$F2" -c copy -movflags +faststart "$OUTF"
