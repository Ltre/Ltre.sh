# termux-change-repo，更换三个资源库为 tsinghua（清华大学）
# pkg i openssh
# 通过whoami得到用户名为 u0_a309
# 执行sshd启动服务
# 最后就可以在别的同内网机器建立SSH连接，端口默认8022
ssh -lu0_a309 -p8022 172.16.15.155
