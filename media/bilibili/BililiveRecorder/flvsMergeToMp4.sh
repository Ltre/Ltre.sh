## 针对从B站直播录制的flv文件进行安全转换合并，摒弃flv带来的音画不同步的问题
## 执行此脚本，需先 cd 到存放flv的目录下，且要求flv文件全部都处于当前目录层

safedir=`pwd`/`date +%Y%d%m%H%M%S`
listfile=$safedir/list.txt
mkdir $safedir
echo "" > $listfile

# 按修改时间, 批量复制到一个安全目录并按编号改名
count=0; for ff in `ls *.flv -rt`; do let count++; cp "$ff" "$safedir/$count.flv"; done;

if [ $count -le 1 ]; then echo 'no flv files'; exit; fi

# 边转换flv->mp4，边生成 [合并专用的配置文件]
i=1
while(( $i<=count )) 
do
    ffmpeg -i $safedir/$i.flv -c copy $safedir/$i.mp4
    echo "file '$i.mp4'" >> $listfile
    let i++
done

# 删除没用的flv片段
currd=`pwd`
cd $safedir #防止误删根目录文件
rm *.flv -f
cd $currd

# 开始合并mp4
mkdir $safedir/result
ffmpeg -f concat -i $listfile -c copy $safedir/result/merge.mp4

# 删除没用的mp4片段
cd $safedir #防止误删根目录文件
rm *.mp4 -f

echo "Complte! $safedir/result/merge.mp4"
