# 此用于 termux 内的 ~/links/* 文件链接，使用后，用pwd看当前目录，会处于目标目录，而非链接的路径
# 为方便使用：设置了此脚本的链接
#       ln  -s  ~/bin/gotolink.sh  $PREFIX/bin/gotolink
# 调用方式(注意用点号开头):  . gotolink examplelink
cd `ls -l ~/links/"$1"|awk 'NF{print $NF}'`
