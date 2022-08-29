# 导出视频所有帧，并启动一个临时的http服务提供浏览
# ./exp-vid-frame-http.sh abc.mp4

inputV=$1
taskdir=~/tmp/expvg/`date +%Y%m%d-%H%M%S`
mkdir -p $taskdir
ffmpeg -i "$1" $taskdir/out%03d.jpg


echo "<?php
\$files = glob('*.jpg');
\$n = count(\$files);
\$p = @\$_GET['p'] ?: 1;
\$prev = max(\$p-1, 1);
\$limit = @\$_GET['limit'] ?: 200;
\$next = min(\$p+1, ceil(\$n/\$limit));
\$offset = \$limit * (\$p - 1);
echo \"<!DOCTYPE html> <meta charset='utf-8'>;
<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>;
    <link rel='stylesheet' type='text/css' href='https://shoes-admin.funfet.com/res/style/font-awesome-4.7.0/css/font-awesome.css'>
    <link rel='stylesheet' type='text/css' href='https://shoes-admin.funfet.com/res/style/loading.css'>
    <link rel='stylesheet' href='https://shoes-admin.funfet.com/res/lib/bootstrap/4.6.1/css/bootstrap.min.css'>
    <script src='https://shoes-admin.funfet.com/res/lib/jquery/jquery-1.11.3.min.js'></script>
    <script src='https://shoes-admin.funfet.com/res/lib/popper.js/1.12.9/umd/popper.min.js'></script>
    <script src='https://shoes-admin.funfet.com/res/lib/bootstrap/4.6.1/js/bootstrap.min.js'></script>
    <script src='https://shoes-admin.funfet.com/res/lib/cookieUtil.js'></script>
    <script src='https://shoes-admin.funfet.com/res/lib/timing.js'></script>
    <script src='https://shoes-admin.funfet.com/res/lib/clipboard/clipboard.min.js'></script>

<style>
body {
  background-color: #343434;
}

#cover {
  width: 1000px;
  height: 1800px;
  margin: 0 auto;
}

#cover > img {
  float: left;
  border: 2px solid black;
  width: 30%;
  margin: 1.66%;
}
</style>
\";

echo \"p=\$p, offset=\$offset, limit=\$limit <br>\";
echo \"<button id='map' style='background-color:royalblue;'>监控大爷</button>\";
echo \"<a href='?p=\$prev'><h1>Prev</h1></a>\";
echo \"<a href='?p=\$next'><h1>Next</h1></a>\";
echo \"<br>\";

//echo \"<div class='container'>\";
//echo \"  <div class='row'>\";
echo \"<div id='cover'>\";
foreach (\$files as \$k => \$f) {
  if (\$k < \$offset || \$k >= \$limit * \$p) continue;
    //echo \"  <div class='col-3 selc' style='border:1px red solid;height:150px'> <img src='\$f' style='display:none1;' ></div>\";
    echo \"<img src='\$f'>\";
}
//echo \"  </div>\";
echo \"</div>\";

echo \"<a href='?p=\$prev'><h1>Prev</h1></a>\";
echo \"<a href='?p=\$next'><h1>Next</h1></a>\";
echo \"<br>\";

echo '<button style=\"posision:fixed; right:0; top:0; display:block; background-color: green; z-index:999;\">EXPORT</button>';

echo '<script src=\"//pub.ouj.com/common/js/jquery.js\"></script>';
echo \"<script>
  function refreshImgShow(){
    \$('img').each((i,e) => {
      \$(e).css('width', \$(e).parents('.selc').width());
    });
  }
  \\\$('.selc').click(function(){
    \\\$(this).css('background-color', 'greenyellow');
    \\\$('#map').click(function({
      \\\$('.selc').removeClass('col-10').addClass('col-1');
    });
    refreshImgShow();
  });

  refreshImgShow();
</script>\";
" > $taskdir/index.php

# nohup termux-open-url 0.0.0.0:2222 &


php -S 0.0.0.0:2222 -t $taskdir
