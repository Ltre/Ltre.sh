## 执行此脚本，需先 cd 到存放mp4的目录下，且要求mp4文件全部都处于当前目录层
## 注意检查每个视频文件规格是否相似（宽高、编码等）

safedir=`pwd`/`date +%Y%m%d%H%M%S`
listfile=$safedir/list.txt
mkdir $safedir
mkdir $safedir/result
echo "" > $listfile

# 按修改时间, 批量复制到一个安全目录并按编号改名
count=0; for ff in `ls *.mp4 -rt`; do let count++; echo "copy: $ff -> $safedir/$count.mp4"; cp "$ff" "$safedir/$count.mp4"; done
# rsync -ah --progress "$ff" "$safedir/$count.mp4"

if [ $count -lt 1 ]; then echo 'no mp4 files'; exit; fi


if [ $count -eq 1 ]
then 
    ffmpeg -i $safedir/1.mp4 -c copy $safedir/result/merge.mp4
    rm $safedir/1.mp4 -f
else

    # 边转换flv->mp4，边生成 [合并专用的配置文件]
    i=1
    while(( $i<=count )) 
    do
        echo "file '$i.mp4'" >> $listfile
        let i++
    done
    
    # 开始合并mp4
    ffmpeg -f concat -i $listfile -c copy $safedir/result/merge.mp4

    # 删除没用的mp4片段
    rm $safedir/*.mp4 -f

fi

echo "=================================================
Complte! $safedir/result/merge.mp4"
