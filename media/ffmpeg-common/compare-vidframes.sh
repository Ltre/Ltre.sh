#!/bin/bash


# 需要 pkg install imagemagick

# ffmpeg输入两个内容相同但清晰程度可能不同的视频，按帧顺序，将两个视频的帧每隔15帧截图后以左右格局合成为一张图，以数字从1开始作为名称对这张合成图命名，放入新建的临时目录，以便用户能逐张图片审阅对比两个视频的清晰度差别

# 支持N张视频帧图片审阅对比。

# 当N为2时，从左到右横向合成图片；
# 当N为3~4时，从左到右并换行（边长为2的田字格布局）合成图片；
# 当N为5~9时，从左到右并换行（边长为3的田字格布局）合成图片，不足9张的则填入黑色；
# 当N为10~16时，从左到右并换行（边长为4的田字格布局）合成图片，不足16张的则填入黑色；
# 当N为17~25时，从左到右并换行（边长为5的田字格布局）合成图片，不足25张的则填入黑色；
# 。。。。。。
# 当N>2，田字格的格子个数的增长数列是4,9,16,25,36,49,64,81...
# 对应的边长数列是2,3,4,5,6,7,8,9...
# 例如输入7个视频，可知 4<7<9，应采用边长为3的田字格
# 例如输入30个视频，可知 25<30<36，应采用边长为6的田字格
# 合成图片方式以此类推
# 合成图片时，对每个格子的图加上双细线边框以便区分

# 这个脚本可接受无限的输入视频文件路径参数
# 设置参数例如" -g 15"，表示两个截取帧的间隔帧数为15



# 检查输入参数
if [ "$#" -lt 2 ]; then
    echo "请至少提供两个视频文件路径作为参数。"
    exit 1
fi

# 获取视频文件列表
videos=("$@")
N=${#videos[@]} # 视频数量

# 默认截取间隔帧数
gap=15

# 临时目录
output_dir="comparison_frames"
mkdir -p "$output_dir"

# 提取所有视频的帧
for i in "${!videos[@]}"; do
    ffmpeg -i "${videos[$i]}" -vf "select=not(mod(n\\,$gap)),setpts=N/FRAME_RATE/TB" -vsync vfr "$output_dir/v$((i + 1))_frame_%04d.png" -hide_banner -loglevel error
done

# 获取最大帧数
max_frames=$(ls "$output_dir"/v1_frame_*.png 2>/dev/null | wc -l)

# 动态计算田字格边长
calculate_side_length() {
    local count=$1
    local side=1
    while (( side * side < count )); do
        (( side++ ))
    done
    echo "$side"
}

# 合成多帧对比图
for ((frame_index=1; frame_index<=max_frames; frame_index++)); do
    frame_files=()
    for i in "${!videos[@]}"; do
        frame_file=$(printf "$output_dir/v%d_frame_%04d.png" $((i + 1)) "$frame_index")
        if [[ -f "$frame_file" ]]; then
            frame_files+=("$frame_file")
        else
            frame_files+=("null:black") # 用黑色填充
        fi
    done

    # 动态布局逻辑
    if [ "$N" -eq 2 ]; then
        # 两个视频：左右拼接
        magick "${frame_files[0]}" "${frame_files[1]}" +append "$output_dir/comparison_${frame_index}.png"
    else
        # 多视频：动态田字格布局
        side_length=$(calculate_side_length "$N")
        total_cells=$((side_length * side_length))
        extra_cells=$((total_cells - N))
        
        # 填补黑色图片到布局单元格
        for ((j=0; j<extra_cells; j++)); do
            frame_files+=("null:black")
        done

        magick montage "${frame_files[@]}" -tile "${side_length}x${side_length}" -geometry +2+2 "$output_dir/comparison_${frame_index}.png"
    fi
done

# 清理临时单帧
rm "$output_dir"/v*_frame_*.png

echo "合成完成！所有对比图已存储在目录：$output_dir"
