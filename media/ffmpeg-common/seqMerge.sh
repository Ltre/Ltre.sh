#!/bin/bash

# 合并视频
# 使用示例: ~/bin/seqMerge.sh -o /path/to/output.mp4 1.mp4 2.mp4 /path/to/3.mp4

# 默认的输出目标位置
default_output_dir="/sdcard/1"
mkdir -p $default_output_dir

# 检查是否有足够的输入参数
if [ "$#" -lt 2 ]; then
  echo "用法: $0 [-o 输出文件] 输入文件1 输入文件2 [输入文件3 ...]"
  exit 1
fi

firstFileName=$(basename "${1%.*}")

# 使用数组来存储输入文件
input_files=()
output_file="$default_output_dir/${firstFileName}_merge_$(date +"%Y%m%d%H%M%S").mp4"
log_file="${default_output_dir}/${firstFileName}_log_$(date +"%Y%m%d%H%M%S").txt"

{

  echo "开始执行合并操作: $(date)" 
  echo "输入的视频文件: $@" 

  # 拼接视频
  ffmpeg -f concat -safe 0 -i <(for file in "$@"; do echo "file '$file'"; done) -c copy "$output_file"
  if [ $? -eq 0 ]; then
    echo "视频已成功拼接到 $output_file。"
  else
    echo "错误: 拼接视频时出现问题。"
  fi

} 2>&1 | tee -a "${log_file}"

echo "合并日志文件的全路径为: $log_file"

