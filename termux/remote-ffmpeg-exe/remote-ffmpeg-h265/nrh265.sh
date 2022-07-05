CUR_DIR="$(dirname "$(readlink -f "$0")")"

ARGS=("$@")  

if [[ $# = 0 ]]; then less  "$CUR_DIR"/readme.md; exit; fi

VDPATH=${ARGS[$(($#-1))]}       # 输入文件名
c=""                            # ffmpeg命令的crf残片
s=""                            # 本地生成文件名后缀的crf部分            

while getopts "c:s:" optname; do 
    case "$optname" in
        c)
            c=" -c ${OPTARG} "
            ;;    
	s)           
	    s=" -s ${OPTARG} "   
	    ;;                                                                 *)     
	    echo 'error arg option: -${optname}.'         
	    exit    
	    ;;  
    esac      
done



if ! [[ -e "${VDPATH}" ]]; then     
    echo "错误：输入的文件不存在"                                      
    exit
fi




nohup "$CUR_DIR"/rh265.sh $c $s "$VDPATH" 2>&1  > "$VDPATH.nohup" &
echo "________________________________"
echo "tail -f -n 50 \"$VDPATH.nohup\""
echo "────────────────────────────────"

sleep 1

tail -f -n 50 "$VDPATH.nohup"
