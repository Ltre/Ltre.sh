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
      -H 'Origin: http://www.caonimabi.com/' \
      -H 'Pragma: no-cache' \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36' \
      -H 'X-Requested-With: XMLHttpRequest' \
      --data-raw "params[chat_id]=-1001560518620&params[text]=${1}" \
      --insecure
}

_jq() {
    echo ${row} | base64 --decode | jq -r ${1}
}

_saveAndSendNotify(){
    for row in $(echo `termux-notification-list`|jq -r '.[] | @base64')
    do
        # 查库是否存在
        notifyTime=$(_jq '.when')
        _find=`sqlite3 ~/tmp/laoda.sqlite "select * from notify where time = '${notifyTime}'" -json`
        
        tmptmp=$(echo $_find|jq ".[0].id")
        #tmptmp=`echo $tmptmp | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'` # 删除两侧由jq赠送的双引号，他妈的！
        tmptmp=${tmptmp:-1}
        
        if [[ x$tmptmp -eq x"1" ]]
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
            # 发送给机器人 
            
            #_id=`_urlencode "$_id"` # 【注释下同】暂时不编码了，因为发现个别内容转换后会被curl警告非UTF-8
            #_tag=`_urlencode "$_tag"`
            #_key=`_urlencode "$_key"`
            #_group=`_urlencode "_group"`
            #_packageName=`_urlencode "$_packageName"`
            #_title=`_urlencode "$_title"`
            #_content=`_urlencode "$_content"`
            #_time=`_urlencode "$_time"`
            
            _forward "- id: ${_id}
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

_saveAndSendNotify

