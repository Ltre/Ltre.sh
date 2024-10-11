# 下载某个频道的所有视频对应的音频
# 遍历yt-dlp得到的音频列表，找出音质最高的m4a格式下载下来
# 默认保存目录: /sdcard/1/ytdl/channel-audio-dl 。在此目录新建频道名称的文件夹，其内有该频道的音频
# python yt-ch-audios-dl.py youtube频道主页链接 --cookies 可选的youtube用户cookies文件( 使用NETSCAPE格式，默认文件~/cookies/youtube.txt) --dlpath 可选的下载目录位置(默认:/sdcard/1/ytdl/channel-audio-dl)
import yt_dlp
import argparse

def download_channel_audios(channel_url, download_path, cookies_path):
    # yt-dlp 配置
    ydl_opts = {
        'format': '140/bestaudio[ext=m4a]/bestaudio',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'm4a',
            'preferredquality': '0',  # 请求最高质量
        }],
        'outtmpl': download_path + '/%(uploader)s/%(title)s.%(ext)s',  # 保存路径和文件 名
        'ignoreerrors': True,  # 忽略下载错误
        'noplaylist': False,  # 允许下载频道/播放列表中的所有视频
        'quiet': False,  # 输出详细信息
        'cookiefile': cookies_path  # 指定cookies文件
    }

    # 使用配置下载
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([channel_url])

if __name__ == "__main__":
    # 设置命令行参数解析
    parser = argparse.ArgumentParser(description='Download audio from a YouTube channel.')
    parser.add_argument('channel_url', help='YouTube channel URL')
    parser.add_argument('--dlpath', default='/sdcard/1/ytdl/channel-audio-dl', help='Path to save downloaded audios (default: /sdcard/1/ytdl/channel-audio-dl)')
    parser.add_argument('--cookies', default='~/cookies/youtube.txt', help='Path to cookies file (default: ~/cookies/youtube.txt)')

    # 解析命令行输入
    args = parser.parse_args()

    # 调用下载函数
    download_channel_audios(args.channel_url, args.dlpath, args.cookies)
