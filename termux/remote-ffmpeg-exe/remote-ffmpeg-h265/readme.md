# 利用ssh和rsync远程执行ffmpeg，完成后取回结果。

## 环境要求
    - 部署于Android Termux App内（ ~/bin/remote-ffmpeg-h265 ）
    - pkg i sshpass #用于自动输入远程机SSH密码
    - pkg i rsync # 用于上传原视频和从远程下载结果视频，不论是本地和远程都需要安装
    - 本地提前做好SSH对远程机器的信任，便于sshpass顺利执行（执行命令 ssh ... 对应机器地址； 回车后输入yes，以保存此远程机器到.ssh目录）
    - 远程机器安装ffmpeg
    - 本地和远程执行md5sum命令正常

## 配置文件
    在 ~/bin/remote-ffmpeg-h265/conf 目录下，有若干 rh265.xxx.conf 文件，和一个默认的rh265.conf文件。
    其中，xxx变量是rh265.sh的 -s 参数值。
    每台远程机器，对应一个 rh265.xxx.conf 配置文件。
    当不指定 -s 参数时，会使用默认的rh265.conf文件。
    
## 示例

    - rh265.sh  "视频文件路径.mp4" # 使用默认的服务器配置文件，执行转码
    - rh265.sh -s mm -c 23 "视频文件路径.mp4"  # 指定服务器配置文件 conf/rh265.mm.conf，并设置 ffmpeg 的 -crf 参数值为23
    - nrh265.sh 参数用法跟 rh265.sh 一样，只不过这个命令会以 nohup rh265.sh xxxx 形式运行，并在原视频目录自动生成同名的nohup日志备胎文件，隔1秒用使用tailf命令呈现此nohup的滚动日志，使用者可以放心按下CTRL+C，不会中断进程。
    - status.sh  # 列出所有任务信息，以及每台服务器的ffmpeg/rsync任务数，以便合理指定空闲的机器执行任务
    - stop-clear.sh  # kill掉所有ffmpeg/rsync相关的进程，并清理(未开发)相关残留垃圾。 （！！！不到万不得已，不要使用，除非你机器有故障）
    - logmap.sh # 查看转码历史日志总览（原文件路径 映射到 日志路径）

## 作者常用的捷径设置
    ln -s ~/bin/remote-ffmpeg-h265/rh265.sh ~/bin/rh265
    ln -s ~/bin/remote-ffmpeg-h265/nrh265.sh ~/bin/nrh265
    ln -s ~/bin/remote-ffmpeg-h265/logmap.sh ~/bin/rl265
    ln -s ~/bin/remote-ffmpeg-h265/status.sh ~/bin/rt265   #不使用rh开头，这样可方便用少量前缀加TAB自动补全命令
    #更加偷懒的方式 （$PREFIX是termux的内置变量，对应 /data/data/com.termux/files ）
    ln -s ~/bin/rh265  $PREFIX/bin/rh265
    ln -s ~/bin/nrh265  $PREFIX/bin/nrh265
    ln -s ~/bin/rl265  $PREFIX/bin/rl265
    ln -s ~/bin/rt265  $PREFIX/bin/rt265

## 对于客户端自动生成文件的说明
    假定视频文件名为 abc.mp4, 任务的进程ID是123, 指定的服务器配置文件名中缀(-s参数)是mm, 指定CRF值(-c参数)是18, 随机生成的远程视频源文件名20220628-173848-5481。
    
    生成的文件放在原视频的同一个目录下。
    
    上传前：
        abc.mp4.mm.crf18.pid.123        # PID标记文件
        abc.mp4.mm.crf18.locallog.sh    # 便于查看本地日志的脚本文件。  请务必使用  bash xxxx.locallog.sh 的方式查看
        . #在本程序的目录的自留日志文件（即便使用者没有指定日志或指定了，都可以在这里找到日志备胎，很贴心吧？）
        {remote-ffmpeg-h265程序目录}/logs/20220628-173848-5481-pid-123.log
        
    上传后：
        abc.mp4.mm.crf18.input.md5      # 上传到远程机器后，在远程计算md5文件，并下载到本地，用于完整性校验
        
    开始远程ffmpeg命令时：
        abc.mp4.mm.crf18.output.size    # 远程执行中，产生的即时结果(mkv文件)的大小描述文件，给人看的，对于程序运行逻辑来讲没什么用
        abc.mp4.mm.crf18.remotelog.sh   # 便于查看远程日志的脚本文件。 请务必使用  bash xxxx.remotelog.sh 的方式查看
        
    检测到远程ffmpeg执行完毕时：
        abc.mp4.mm.crf18.finished       # 在等待远程任务的循环逻辑中，会不断尝试下载finished文件，一旦真的下载到了，那就表示远程ffmpeg执行完毕了
        
    取回远程结果时：
        abc.mp4.mm.crf18.output.md5     # 远程结果文件(mkv)的最终md5，用于判断是否完整下载
        
    程序结束时：
        会生成 abc.mp4.mm.crf18.mkv  # 转码结果文件
        会清理 *.md5、*.size、*.finished、*.remotelog.sh *.locallog.sh
        会归档 {remote-ffmpeg-h265程序目录}/logs/end/20220628-173848-5481-pid-123.log  # 移动到程序源码的logs/end目录

## 一些错误说明
    很多错误基本来源于网络的波动，这点非常无解，尽管在程序上做了重试工作，还是有意料不到的事发生。（水平有限）
    1、有时文件并未完整上传到服务器，但程序认为上传完毕，直接跳到远程ffmpeg执行步骤，导致后面的步骤都出错；
    2、在等待远程ffmpeg任务阶段，可能会出现某些错误，在远程生成了finished标识文件，导致本地客户端误认为任务完成了，导致后面的步骤都出错；
    3、在等待远程ffmpeg任务阶段，可能会因为ffmpeg挂掉，使得远程永远无法生成finished标识文件，导致本地客户端一直等待任务，永不停止；
    4、在远程结果文件取回阶段，rsync可能会因为网络波动等原因，僵死在某个状态又不会自己重新下载。
        这时就需要登录服务器查看任务是否真正完成，确认后，准确定位本地这个僵死的rsync进程（不能是它的任务父进程），将其kill，这样才会重新触发文件取回操作。

## 如何使用日志
    所有日志位于

## 关于ffmpeg的说明：
    - 适合不需要看太清楚细节的视频压缩。
    - 喜欢看action片的且有保留完整细节强迫症的盆友请绕道。（因为h265得到的结果文件的细节常有涂抹观感，类似微观马赛克）

    - 自用转码方案优先级：
        ffmpeg -i xxx.mp4 yyy.mp4
            (无参数直接转：体积相对不大质量好速度相对快，适用于h264原片) 
        > ffmpeg -i xxx.mp4 -c:v libx265 -c:a copy -crf 18 -movflags +faststart -yyy.mkv
            (-crf 18体积最大质量好速度快)   @todo： 试试 -crf 20 ?
        > ffmpeg -i xxx.mp4 -c:v libx265 -c:a copy -preset veryslow -movflags +faststart -yyy.mkv
            (-preset veryslow体积最小质量好速度非常慢)
        > ffmpeg -i xxx.mp4 -c:v libx265 -c:a copy -movflags +faststart -yyy.mkv
            (h265无附加参数，体积小质量勉强可以速度一般)
    - preset由快到慢：
        ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo.
        当使用x265编码器时, 默认为medium.
    - crf参数：
        0 ~ 51.
        当使用x265编码器时, 默认为28, 20左右视觉无损.
        
        
        
        
## 后记
    笔者在完成此项目后，才去网络上搜了一通，找到别人实现的远程ffmpeg，地址：https://github.com/dannytech/ffmpeg-remote-transcoder/blob/main/frt.py
    有空去研究下他的，把好的地方学习进来。