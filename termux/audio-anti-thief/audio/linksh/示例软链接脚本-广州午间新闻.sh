# 脚本制作方法：
# 先 cd /sdcard/存档/临时/termux防盗音频/广州午间新闻
# 执行 ls > list.txt
# notepad++打开 list.txt，补充齐每个文件名的两侧单引号， 
# 再用正则表达式将【'[^']+'】替换为【ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/$0 $0】
# 即可得到如下脚本：

cd ~/mydir/bin/audio-anti-thief/audio  #先进入需要部署链接的目录


ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州6点新闻【粤语】20181127（高清）-GETkeELPX64.m4a' '广州6点新闻【粤语】20181127（高清）-GETkeELPX64.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181206-Q0fYi1XA6l0.m4a' '广州午间新闻【粤语】20181206-Q0fYi1XA6l0.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181210（高清）-BdlUlZ5iOHs.m4a' '广州午间新闻【粤语】20181210（高清）-BdlUlZ5iOHs.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间12点半新闻【粤语】20181024-LAZc26RLWDA.m4a' '广州午间12点半新闻【粤语】20181024-LAZc26RLWDA.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181207（高清）-8IYY8iyos5o.m4a' '广州午间新闻【粤语】20181207（高清）-8IYY8iyos5o.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181211（高清）-rQDhDIENnQo.m4a' '广州午间新闻【粤语】20181211（高清）-rQDhDIENnQo.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间12点半新闻【粤语】20181025（高清）-uDdlp130ZBk.m4a' '广州午间12点半新闻【粤语】20181025（高清）-uDdlp130ZBk.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181209（高清）-sDUn4uYJScU.m4a' '广州午间新闻【粤语】20181209（高清）-sDUn4uYJScU.m4a'
ln -s /sdcard/存档/临时/termux防盗音频/广州午间新闻/'广州午间新闻【粤语】20181212（高清）-GY_pVSY77Iw.m4a' '广州午间新闻【粤语】20181212（高清）-GY_pVSY77Iw.m4a'

