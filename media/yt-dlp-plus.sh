#!/bin/bash

# 将此脚本加入软链： ln -s ~/bin/yt-dlp-plus.sh $PREFIX/bin/yt-dlpp

# yt-dlpp (懒人版yt-dlp) for Termux
# 原yt-dlp: pip install yt-dlp
# env: python, ffmpeg, pip
#
# 特性：
# 1. 封装yt+dlp，取个新名字叫 yt-dlpp，默认缺省使用cookies参数，内部实现形如“  yt-dlp --cookies ~/cookies/youtube.txt ”，对于yt-dlpp的用法，和原yt-dlp保持一致
# 2. 新增 --FF 参数。当传入 --FF，将始终调用 -F 参数，并推荐视频+音频组合信息；在没有传入 --FF 参数时，即使有 -F 参数传入，也保持 yt-dlp 的默认行为。
# 3. 默认进入目录/sdcard/1/ytdl，除非手动指定 -o 参数

mkdir -p /sdcard/1/ytdl
cd /sdcard/1/ytdl

# 默认的 cookies 文件路径
COOKIES_FILE=~/cookies/youtube.txt
# COOKIES_FILE=~/cookies/ytm.cookie

# 检查 cookies 文件是否存在
if [ ! -f "$COOKIES_FILE" ]; then
  echo "Cookies 文件不存在: $COOKIES_FILE"
  exit 1
fi

# 公共参数
#COMMON_CMD=' --extractor-args "youtube:player_client=android" --cookies $COOKIES_FILE '
COMMON_CMD=' --cookies $COOKIES_FILE '

# 初始化变量
FF_FLAG=false

# 检查是否包含 --FF 参数
for arg in "$@"; do
  if [ "$arg" == "--FF" ]; then
    FF_FLAG=true
    # 移除 --FF 参数
    set -- "${@/--FF/}"
    break
  fi
done

# 如果启用推荐功能，调用 -F 参数
if [ "$FF_FLAG" = true ]; then
  # 构建命令
  COMMAND="yt-dlp $COMMON_CMD -F $@"

  # 执行命令并捕获输出
  eval $COMMAND 2>&1 | tee yt-dlp_output.log

  if [ $? -ne 0 ]; then
    echo "yt-dlp 命令执行失败，请查看日志: yt-dlp_output.log"
    exit 1
  fi

  # 分析格式信息并推荐组合
  #VIDEO_FORMATS=$(grep -E '^[0-9]+.*[0-9]+x[0-9]+.*video' yt-dlp_output.log | awk '{print $1, $2, $3, $4, $5, $6}')
  #AUDIO_FORMATS=$(grep -E '^[0-9]+.*audio' yt-dlp_output.log | awk '{print $1, $2, $4, $5}')

  VIDEO_FORMATS=$(grep -E '^[0-9]+.*[0-9]+x[0-9]+.*video' yt-dlp_output.log)
  AUDIO_FORMATS=$(grep -E '^[0-9]+.*audio' yt-dlp_output.log)


  if [ -z "$VIDEO_FORMATS" ]; then
    echo "未找到视频格式信息。"
    exit 1
  fi

  if [ -z "$AUDIO_FORMATS" ]; then
    echo "未找到音频格式信息。"
    exit 1
  fi

  echo;echo;echo
  echo "推荐的视频+音频组合："
  while IFS= read -r VIDEO; do
    VIDEO_ID=$(echo "$VIDEO" | awk '{print $1}')
    VIDEO_EXT=$(echo "$VIDEO" | awk '{print $2}')
    VIDEO_RES=$(echo "$VIDEO" | awk '{print $3}')
    VIDEO_FPS=$(echo "$VIDEO" | awk '{print $4}')
    VIDEO_FILESIZE=$(echo "$VIDEO" | sed -nE 's/.*\|\s*~?\s*([0-9]+\.?[0-9]*[KMGkmg][Ii][Bb]).*/\1/p')
    VIDEO_TBR=$(echo "$VIDEO" | sed -nE 's/.*\|\s*~?\s*[0-9]+\.?[0-9]*[KMGkmg][Ii][Bb]\s+([0-9]+\.?[0-9]*[KMGkmg]).*/\1/p')
    VIDEO_CODEC=$(echo "$VIDEO" | sed -nE 's/.*\|\s*~?\s*[0-9]+\.?[0-9]*[KMGkmg][Ii][Bb]\s+[0-9]+\.?[0-9]*[KMGkmg]\s+[^|]+\s*\|\s*([0-9a-zA-Z.]+).*/\1/p')
    VIDEO_PROTO=$(echo "$VIDEO" | sed -nE 's/.*\|\s*[0-9]+\.?[0-9]*[KMGkmg][Ii][Bb]\s+[0-9]+\.?[0-9]*[KMGkmg]\s+([0-9a-zA-Z.]+).*/\1/p')
    while IFS= read -r AUDIO; do
      AUDIO_ID=$(echo "$AUDIO" | awk '{print $1}')
      AUDIO_EXT=$(echo "$AUDIO" | sed -nE 's/^[0-9]+\s+([0-9a-zA-Z.]+).*/\1/p')
      AUDIO_TBR=$(echo "$AUDIO" | sed -nE 's/^[0-9]+[^|]+\|\s*[0-9]+\.?[0-9]*[KMGkmg][Ii][Bb]\s+([0-9]+[KMGkmg]).*/\1/p')
      AUDIO_CODEC=$(echo "$AUDIO"  | sed -nE 's/^[0-9]+[^|]+\|[^|]+\|\s*audio\s+only\s+([0-9a-zA-Z.]+).*$/\1/p')
      AUDIO_PROTO=$(echo "$AUDIO" | sed -nE 's/^[0-9]+[^|]+\|\s*[^|]+\s+([0-9a-zA-Z.]+)\s*\|.*/\1/p')
      AUDIO_FILESIZE=$(echo "$AUDIO" | sed -nE 's/^[0-9]+[^|]+\|\s*([0-9.]+[KMGkmg][Ii][Bb]).*/\1/p')
      echo "$VIDEO_ID+$AUDIO_ID - ${VIDEO_RES}@${VIDEO_FPS}fps, ${VIDEO_FILESIZE},${VIDEO_TBR},${VIDEO_CODEC},${VIDEO_EXT},${VIDEO_PROTO} - ${AUDIO_FILESIZE},${AUDIO_TBR},${AUDIO_CODEC},${AUDIO_EXT},${AUDIO_PROTO}"
    done <<< "$AUDIO_FORMATS"
  done <<< "$VIDEO_FORMATS"
else
  # 构建命令
  COMMAND="yt-dlp $COMMON_CMD $@"

  # 执行命令
  eval $COMMAND
fi
