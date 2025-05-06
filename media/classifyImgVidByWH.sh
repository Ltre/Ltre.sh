# ffmpeg将以下路径的图片或视频文件按分辨率分类，每个分类为一个目录，目录名称格式为“widthXheight”

# 检查是否提供了输入目录参数
if [[ -z "$1" ]]; then
    echo "错误：请提供输入目录作为参数" >&2
    exit 1
fi

# 定义输入目录和日志文件
input_dir="$1"
log_file="classifyImgVidByWH.log"

# 检查输入目录是否存在
if [[ ! -d "$input_dir" ]]; then
    echo "错误：目录 $input_dir 不存在" >&2
    exit 1
fi

# 切换到输入目录
cd "$input_dir" || {
    echo "错误：无法进入目录 $input_dir" >&2
    exit 1
}

# 检查 ffmpeg 是否可用
if ! command -v ffprobe &>/dev/null; then
    echo "错误：ffprobe 未安装，请先安装 ffmpeg" >&2
    exit 1
fi

# 初始化日志文件
echo "分辨率分类开始: $(date)" > "$log_file"

# 查找图片和视频文件
find . -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
       -iname '*.mp4' -o -iname '*.avi' -o -iname '*.mkv' -o \
       -iname '*.mov' -o -iname '*.flv' -o -iname '*.wmv' \) -print0 |
while IFS= read -r -d '' file; do
    # 获取分辨率
    resolution=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height -of csv=p=0:s=x "$file" 2>/dev/null)

    # 检查分辨率格式
    if [[ "$resolution" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        width=${BASH_REMATCH[1]}
        height=${BASH_REMATCH[2]}
        dir_name="${width}x${height}"

        # 创建分辨率目录
        mkdir -p "$dir_name"

        # 移动文件
        if mv "$file" "$dir_name/"; then
            echo "已移动: $file -> $dir_name" >> "$log_file"
        else
            echo "移动失败: $file" >> "$log_file" >&2
        fi
    else
        # 尝试获取图片分辨率（备用方法）
        if [[ "$file" =~ \.(jpg|jpeg|png)$ ]]; then
            resolution=$(identify -format "%w x %h" "$file" 2>/dev/null)
            if [[ "$resolution" =~ ^([0-9]+)[[:space:]]x[[:space:]]([0-9]+)$ ]]; then
                width=${BASH_REMATCH[1]}
                height=${BASH_REMATCH[2]}
                dir_name="${width}x${height}"

                mkdir -p "$dir_name"
                if mv "$file" "$dir_name/"; then
                    echo "已移动(图片): $file -> $dir_name" >> "$log_file"
                else
                    echo "移动失败(图片): $file" >> "$log_file" >&2
                fi
            else
                echo "无法识别分辨率: $file" >> "$log_file" >&2
            fi
        else
            echo "无法识别分辨率: $file" >> "$log_file" >&2
        fi
    fi
done

echo "分类完成: $(date)" >> "$log_file"
