# 开发中

#!/data/data/com.termux/files/usr/bin/bash

CUR_DIR="$(dirname "$(readlink -f "$0")")"

# 列出所有非hevc的视频文件，合理控制个数，并行执行远程转码。
# 还支持随机选择远程机器（最好能了解机器负载情况，和ffmpeg任务数）


# for i in `ls *.mp4`; do echo "rh265 -swebdev $i 2>&1 > $i.nohup" >> list; done
# for i in `ls *.mp4`; do echo "nohup rh265 -sgzz $i 2>&1 > $i.nohup &" >> list; done

# 参数
#       -c 可定制 ffmpeg 的crf参数值 （可选）
#       -s 指定配置文件的简称，例如 -s mm 会指定 rh265.mm.conf  （可选）
CRF=""                      # ffmpeg命令的crf残片
SERV=""                     # 带有服务器简称的文件名中缀残片
while getopts "c:s:" optname; do
    case "$optname" in
        c)
            CRF=" -c ${OPTARG} "
            ;;
        s)
            SERV=" -s ${OPTARG} "
            ;;
        *)
            echo 'error arg option: -${optname}.'
            exit
            ;;
    esac
done





listname=`date +%Y%m%d-%H%M%S`-$((RANDOM%10000)).list
ls *.mp4 2>/dev/null >> $listname
ls *.MP4 2>/dev/null >> $listname
ls *.mov 2>/dev/null >> $listname
ls *.MOV 2>/dev/null >> $listname
ls *.avi 2>/dev/null >> $listname
ls *.AVI 2>/dev/null >> $listname
ls *.rmvb 2>/dev/null >> $listname
ls *.RMVB 2>/dev/null >> $listname
ls *.wmv 2>/dev/null >> $listname
ls *.WMV 2>/dev/null >> $listname
ls *.m4v 2>/dev/null >> $listname
ls *.M4A 2>/dev/null >> $listname
ls *.ts 2>/dev/null >> $listname
ls *.TS 2>/dev/null >> $listname

while read row; do
    echo $row
    echo bash "${CUR_DIR}"/rh265.sh $SERV $CRF "$row"
done < $listname
