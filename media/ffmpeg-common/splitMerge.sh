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
            fi                                                                                                   ;;
    esac                                                                                                 shift                                                                                            done                                                                                                                                                                                                      # 输入视频文件路径是必需的                                                                           if [ -z "$input_video" ]; then                                                                           echo "请输入输入视频文件路径。"                                                                      exit 1                                                                                           fi                                                                                                                                                                                                        # 创建输出文件名                                                                                     if [ -z "$output_file" ]; then
    output_file="${input_video%.*}$output_suffix"
fi

# 创建分段文件列表
segment_list="segments.txt"
rm -f "$segment_list"

segment_number=1
for cut_range in "${cut_ranges[@]}"; do                                                                  IFS=- read -ra range <<< "$cut_range"
    start_time=${range[0]}
    end_time=${range[1]}

    segment_file="segment$segment_number.mp4"

    ffmpeg -ss "$start_time" -to "$end_time" -i "$input_video" -c:v copy -c:a copy "$segment_file"
    echo "file '$segment_file'" >> "$segment_list"

    segment_number=$((segment_number + 1))                                                           done

# 执行合并操作
ffmpeg -f concat -safe 0 -i "$segment_list" -c:v copy -c:a copy "$output_file"
                                                                                                     echo "视频切割和合并完成，输出文件为 $output_file。"

# 清理临时文件
rm -f "segment*.mp4"
rm -f "$segment_list"
