#!/bin/bash

# 检查是否提供了输入目录参数
if [[ -z "$1" ]]; then
    echo "错误：请提供输入目录作为参数" >&2
    exit 1
fi

# 定义输入目录和输出目录
input_dir="$1"
current_date=$(date +%Y%m%d)  # 获取当前日期（格式：YYYYMMDD）
output_dir="$input_dir/pickedImgVid-$current_date"
log_file="$input_dir/pickImgVidFromSubDirs.log"

# 检查输入目录是否存在
if [[ ! -d "$input_dir" ]]; then
    echo "错误：目录 $input_dir 不存在" >&2
    exit 1
fi

# 创建输出目录
mkdir -p "$output_dir" || {
    echo "错误：无法创建输出目录 $output_dir" >&2
    exit 1
}

# 初始化日志文件
echo "媒体文件提取开始: $(date)" > "$log_file"

# 查找所有图片和视频文件（包括子目录）
find "$input_dir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o \
       -iname '*.mp4' -o -iname '*.avi' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.flv' -o -iname '*.wmv' \) -print0 |
while IFS= read -r -d '' file; do
    # 跳过输出目录中的文件
    if [[ "$file" == "$output_dir"* ]]; then
        continue
    fi

    # 获取文件名（避免路径冲突）
    filename=$(basename "$file")

    # 检查目标文件是否已存在
    if [[ -f "$output_dir/$filename" ]]; then
        # 如果文件已存在，添加时间戳后缀
        timestamp=$(date +%Y%m%d_%H%M%S)
        base="${filename%.*}"
        ext="${filename##*.}"
        new_filename="${base}_${timestamp}.${ext}"
    else
        new_filename="$filename"
    fi

    # 复制文件到输出目录
    if cp "$file" "$output_dir/$new_filename"; then
        echo "已提取: $file -> $output_dir/$new_filename" >> "$log_file"
    else
        echo "提取失败: $file" >> "$log_file" >&2
    fi
done

echo "媒体文件提取完成: $(date)" >> "$log_file"
