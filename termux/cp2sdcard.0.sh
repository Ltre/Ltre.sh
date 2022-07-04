# 批量将文件复制到 /sdcard/.0 目录
# 有什么用？例如telegram选取文件列表中，【.0】目录靠前，这样可以免去费尽翻找文件夹的麻烦
# 为了快速复制原文件路径，建议使用fooview的屏幕文字提取功能
# 相关的操作保存在个人为知笔记：/操作经验/三星S10系列/telegram上传文件免去费劲翻找文件夹的麻烦（巧用termux和fooview）
# termux快捷操作设定建议： ln  -s  ~/bin/cp2sdcard.0  $PREFIX/bin/cp2sdcard.0
mkdir -p /sdcard/.0
cp $@ /sdcard/.0 
