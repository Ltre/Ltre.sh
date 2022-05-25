sqlite3 -append ~/tmp/laoda.sqlite 
    # 在SQLite命令模式下输入以创建表：
        create table notify(`id` varchar(32), `tag` varchar(32), `key` varchar(255), `group` varchar(64), packageName varchar(128), title varchar(128), `content` text, `time` datetime );
        
# 后续就可以在外部shell插入或查询数据了
sqlite3 ~/tmp/laoda.sqlite "insert into notify values(11111, 'tagtag', 'keykeykey', 'groupgroupgroup', 'com.caonima.bi', 'this is a title', 'this is content', '2022-05-25 11:11:11')"
result=`sqlite3 ~/tmp/laoda.sqlite "select * from notify" -json`
echo $result|jq .[1].tag # 配合jq获取具体字段


# sqlite3 ~/tmp/laoda.sqlite "delete from notify"





# 以下为数据同步部分：


result=`sqlite3 ~/tmp/laoda.sqlite "select * from notify" -json`
for row in $(echo `termux-notification-list`|jq -r '.[] | @base64')
do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }
    
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
        
    else
        echo "已有数据，跳过"
    fi
done

