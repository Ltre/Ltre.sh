# 输入视频，按需求将视频切割无限个分段，最后合并成一个视频
# e.g. ~/bin/splitMerge.sh "/path/to/video.mp4" 00:01-00:56 02:05.563-01:01:01 02:03:04.999-05:00:00

# 检查FFmpeg是否已安装
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg未安装，请先安装FFmpeg。"
    exit 1
fi

# 默认的输出文件名后缀
output_suffix="-output.mp4"

# 处理命令行参数
input_video=""
cut_ranges=()
output_file=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            shift
            output_file="$1"
            ;;
        *)
            if [ -z "$input_video" ]; then
                input_video="$1"
            else
                cut_ranges+=("$1")
            fi
            ;;
    esac
    shift
done

# 输入视频文件路径是必需的
if [ -z "$input_video" ] || [ ! -e "$input_video" ]; then
    echo "请输入输入视频文件路径。"
    exit 1
fi

# 由于懒得调试，故直接进入所在目录
cd "$(dirname "$input_video")"

# 获取文件名
input_video=$(basename "$input_video")

# 创建临时文件夹
temp_dir_name="${input_video:0:10}-$(date +'%Y%m%d%H%M%S')"
temp_dir="$temp_dir_name"
mkdir -p "$temp_dir"

# 创建分段文件列表
segment_list="${temp_dir}/segments.txt"
# rm -f "$segment_list"

input_extension="${input_video##*.}"

# 创建缺省输出文件名
if [ -z "$output_file" ]; then
    output_file="${input_video%.*}-output.$input_extension"
fi

segment_number=1
for cut_range in "${cut_ranges[@]}"; do
    IFS=- read -ra range <<< "$cut_range"
    start_time=${range[0]}
    end_time=${range[1]}

    segment_name="segment$segment_number.$input_extension"
    segment_file="${temp_dir}/${segment_name}"

    ffmpeg -ss "$start_time" -to "$end_time" -i "$input_video" -c:v copy -c:a copy "$segment_file"
    echo "file '$segment_name'" >> "$segment_list"

    segment_number=$((segment_number + 1))
done

# 执行合并操作
ffmpeg -f concat -safe 0 -i "$segment_list" -c:v copy -c:a copy "$output_file"

echo "视频切割和合并完成，输出文件为 $output_file。"

# 清理临时文件
echo "是否保留临时分片目录(y/N):"
read jx
if [ "$jx" = "y" ]; then exit; fi
if [ -n "$temp_dir" ] && [ -d "$temp_dir" ] && [ "$temp_dir" != "/" ]; then
    rm -r "$temp_dir"
fi

