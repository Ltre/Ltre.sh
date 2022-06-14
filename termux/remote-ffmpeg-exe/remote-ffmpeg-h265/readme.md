# 利用ssh和rsync远程执行ffmpeg，完成后取回结果。

## 环境
    - pkg i sshpass
    - pkg i rsync
    - ssh ... 对应机器地址 回车后输入yes，以保存此远程机器到.ssh目录，便于sshpass顺利执行
    - 远程机器安装ffmpeg

## 注意：
    - 适合不需要看太清楚细节的视频压缩。
    - 喜欢看action片的且有保留完整细节强迫症的盆友请绕道。（因为h265得到的结果文件的细节常有涂抹观感，类似微观马赛克）
