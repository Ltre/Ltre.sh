CUR_DIR="$(dirname "$(readlink -f "$0")")"

ARGS=("$@")  

if [[ $# = 0 ]]; then less  "$CUR_DIR"/readme.md; exit; fi

VDPATH=${ARGS[$(($#-1))]}       # 输入文件名
c=""                            # ffmpeg命令的crf残片
s=""                            # 本地生成文件名后缀的crf部分            
p=""                            # ffmpeg命令的preset残片
v=""                            # ffmpeg命令的vf残片

while getopts "c:s:p:v:" optname; do 
    case "$optname" in
    c)
        c=" -c ${OPTARG} "
        ;;
    s)
	s=" -s ${OPTARG} "
	;;
    p)
        p=" -p ${OPTARG} "
	;;
    v)
        v=" -v '${OPTARG}'"
        ;;
    *)
	echo "error arg option: -${optname}."
	exit
        ;;
    esac
done



# 文件参数拦截 
# 允许：
#       nrh265 [..options..] rawfile_exists.mp4
#       nrh265 [..options..] rawfile_exists.mp4  movetofile_not_exists.mp4
# 禁止:
#       nrh265 [..options..] rawfile_not_exists.mp4
#       nrh265 [..options..] rawfile_exists.mp4  movetofile_exists.mp4
if ! [[ -e "${VDPATH}" ]]; then
    if [[ $# -eq 1 ]]; then
        echo "错误：输入的文件不存在"
        exit
    fi
    
    # 可能采用了 【rh265 [...] rawfile.mp4  movetofile.mp4】的调用形式（先改名，再转码）
    # MOVETO=$VDPATH
    # VDPATH=${ARGS[$(($#-2))]}
    if ! [[ -e "${ARGS[$(($#-2))]}" ]]; then
        echo "错误：输入的文件不存在"
        exit
    else
        nohup "$CUR_DIR"/rh265.sh $c $s $p $v "${ARGS[$(($#-2))]}" "$VDPATH" 2>&1  > "$VDPATH.nohup" &
        # echo "nohup \"$CUR_DIR\"/rh265.sh $c $s $p $v \"${ARGS[$(($#-2))]}\" \"$VDPATH\" 2>&1  > \"$VDPATH.nohup\" &"
    fi
else
    if [[ $# -eq 1 ]]; then
        nohup "$CUR_DIR"/rh265.sh $c $s $p $v "$VDPATH" 2>&1  > "$VDPATH.nohup" &
        # echo "nohup \"$CUR_DIR\"/rh265.sh $c $s $p $v \"$VDPATH\" 2>&1  > \"$VDPATH.nohup\" &"
    else
        if [[ -e "${ARGS[$(($#-2))]}" ]]; then
            echo "错误：转码前文件改新名失败，因新名所指文件在以前就已存在"
            exit
        else
            nohup "$CUR_DIR"/rh265.sh $c $s $p $v 'ignore_me' "$VDPATH" 2>&1  > "$VDPATH.nohup" &
            # echo "nohup \"$CUR_DIR\"/rh265.sh $c $s $p $v NOPENOPENOPE \"$VDPATH\" 2>&1  > \"$VDPATH.nohup\" &"
        fi
    fi
fi





echo "________________________________"
echo "tail -f -n 50 \"$VDPATH.nohup\""
echo "────────────────────────────────"

sleep 1

tail -f -n 50 "$VDPATH.nohup"
