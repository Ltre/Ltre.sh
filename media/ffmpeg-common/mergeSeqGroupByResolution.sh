# 按文件写入时间顺序，对相邻文件且同等分辨率的，作为一个分组，创建文件夹，将分组中的视频移动到所对应创建的文件夹中，文件夹以"数字-分辨率"命名（从数字1开始，例如1-480x854
# 在视频以分组移动完毕后，按文件夹创建的顺序，分别合并每个文件夹中的视频，将所合并的文件，命名为"数字-分辨率.视频实际扩展名"格式，例如"1-480x854.flv"。如果被合并的多个视频扩展名不同，则最后以mp4作为视频扩展名。接着，将合并好的视频文件，统一存储到上级目录下所创建的groupMerged目录，也就是"../groupMerged"

# 使用方法：cd到视频所在的目录，执行此命令，不需要参数。（注：目录中所有视频文件都会被影响，请确保目录中没有其他不需要操作的视频）

# ------------------执行后生成目录和文件示例------------------
# 1-480x854:
# created_by_script.marker
# 录制-31279533-20231230-133200-327-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-133202-737-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-133205-127-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-133205-857-放假了，去农村，来聊天.flv
# 
# 2-720x1280:
# created_by_script.marker
# 录制-31279533-20231230-133213-908-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-133638-295-放假了，去农村，来聊天.flv
# 
# 3-480x854:
# created_by_script.marker
# 录制-31279533-20231230-134044-331-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-134324-127-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-134326-476-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-134327-138-放假了，去农村，来聊天.flv
# 
# 4-720x1280:
# created_by_script.marker
# 录制-31279533-20231230-134341-910-放假了，去农村，来聊天.flv
# 
# 5-480x854:
# created_by_script.marker
# 录制-31279533-20231230-134931-884-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-134932-616-放假了，去农村，来聊天.flv
# 录制-31279533-20231230-134935-092-放假了，去农村，来聊天.flv

# groupMerged:
# 1-480x854.flv  2-720x1280.flv  3-480x854.flv  4-720x1280.flv  5-480x854.flv
# ------------------------------------------------



# 创建分组合并结果目录
mkdir -p groupMerged

# 定义变量
group_number=1
current_resolution=""

# 遍历目录中的所有视频文件
for video_file in *.flv *.mp4 *.mkv *.avi *.rmvb *.mov *.3gp *.ts; do
    if [ -f "$video_file" ]; then
        # 使用ffmpeg获取视频分辨率信息，并禁用标准输入流交互
        resolution=$(ffmpeg -nostdin -i "$video_file" 2>&1 | grep Stream | grep -oP ', \K[0-9]+x[0-9]+')

        # 如果分辨率变了，创建新的分组文件夹
        if [ "$resolution" != "$current_resolution" ]; then
            current_resolution="$resolution"
            group_folder="${group_number}-${current_resolution}"
            mkdir -p "$group_folder"
            # 创建一个标记文件，表示该文件夹是由脚本创建的
            touch "$group_folder/created_by_script.marker"
            group_number=$((group_number + 1))
        fi

        # 移动视频文件到相应的分组文件夹
        echo "MOVE: $video_file -> $group_folder/"
        mv "$video_file" "$group_folder/"
    fi
done


# 在所有视频移动到对应文件夹完毕后，按文件夹顺序分别合并每个文件夹中的视频
for folder in $(ls -d [0-9]*-* 2>/dev/null | sort -n); do
    cd "$folder" || exit
    echo ">> FOLDER MERGING: $folder"
    # 检查文件夹是否存在标记文件
    if [[ -f "created_by_script.marker" ]]; then
        # 获取实际扩展名
        actual_extension=$(ls -1 | grep -E '\.flv$|\.mp4$|\.mkv$|\.avi$|\.rmvb$|\.mov$|\.3gp$|\.ts$' | head -n 1 | sed 's/.*\.//')
        
        # 合并视频文件
        ffmpeg -nostdin -f concat -safe 0 -i <(for f in *."$actual_extension"; do echo "file '$PWD/$f'"; done) -c copy "../groupMerged/${folder}.${actual_extension:-mp4}"
    fi
    cd ..
done
