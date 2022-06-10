tail -f `ps aux|grep ffmpeg|grep -vw grep|awk '{print "/proc/"$2"/cwd/*.log"}'`

