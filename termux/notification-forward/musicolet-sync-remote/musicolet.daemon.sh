# 配置远程机器信息
# 收集歌曲 【artist - song】和【对应文件路径】到sqlite
# 通过termux-notification-list/jq/sqlite, 找到正在播放歌曲的文件路径
# 后台调用 play-audio-remotely.sh
# 当检测到切换曲目时，kill掉play-audio-remotely.sh，重新以后台调用之
# todo: 20220808 开发，不确定是否开发完成，更不知是否测试成功

getSongPath(){
    echo '/sdcard/存档/原机存档目录/音频整理/AlarmClock/AlarmClockPart7/吕方\ -\ 每段路.m4a'
}

while true; do

    for row in $(echo `termux-notification-list`|jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        if [[ "$(_jq '.packageName')" = "in.krosbits.musicolet" ]]; then
            title=`_jq '.title'`
            artist=`_jq '.content'`
            kill -9 `ps -ef|grep 'play-audio-remotely'|grep -vw grep|awk '{print $2}'` 2>/dev/null
            nohup ~/bin/play-audio-remotely "$(getSongPath "$title" "$artist")" &
        fi    
    done
    
    sleep 3
    echo 'sleep 3...'
done
