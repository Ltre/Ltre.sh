## 执行此脚本，需先 cd 到存放mkv的目录下，且要求mkv文件全部都处于当前目录层

safedir=`pwd`/`date +%Y%m%d%H%M%S`
listfile=$safedir/list.txt
mkdir $safedir
mkdir $safedir/result
echo "" > $listfile

# 按修改时间, 批量复制到一个安全目录并按编号改名
count=0; for ff in `ls *.mkv -rt`; do let count++; echo "copy: $ff -> $safedir/$count.mkv"; cp "$ff" "$safedir/$count.mkv"; done

if [ $count -lt 1 ]; then echo 'no mkv files'; exit; fi


if [ $count -eq 1 ]
then
	echo "只有一个文件，不需要合并"
else

    # 生成 [合并专用的配置文件]
    i=1
    while(( $i<=count )) 
    do
        echo "file '$i.mkv'" >> $listfile
        let i++
    done
    
    # 开始合并mkv
    ffmpeg -f concat -i $listfile -c copy $safedir/result/merge.mkv

    # 删除没用的mkv片段
    rm $safedir/*.mkv -f

fi

echo "=================================================
Complte! $safedir/result/merge.mkv"
