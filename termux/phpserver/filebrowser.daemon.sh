# 一个非常简单的临时文件浏览器，可指定目录和端口
# ~/bin/phpserver/filebrowser.daemon  [FILEROOT]  [PORT]

if [[ "$1" != "" ]]; then
    if ! [ -d "$1" ]; then echo "dir [$1] does not exist"; fi
    FILEROOT="$1"
else
    FILEROOT=`pwd`
fi

if [[ "$2" = "" ]]; then
    PORT=1111
else
    PORT=$2
fi

mkdir -p ~/bin/phpserver/.filebrowser-daemon

echo "<?php

function dl(\$filename){
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header(\"Cache-Control: no-cache, must-revalidate\");
    header(\"Expires: 0\");
    header('Content-Disposition: attachment; filename=\"'.basename(\$filename).'\"');
    header('Content-Length: ' . filesize(\$filename));
    header('Pragma: public');
    flush();
    readfile(\$filename);
    die;
}

function view(\$filename){
    header('Content-Description: File Viewer');
    header('Content-Type: '.mime_content_type(\$filename));
    header(\"Cache-Control: no-cache, must-revalidate\");
    header(\"Expires: 0\");
    //header('Content-Disposition: attachment; filename=\"'.basename(\$filename).'\"');
    header('Content-Length: ' . filesize(\$filename));
    header('Pragma: public');
    flush();
    readfile(\$filename);
    die;
}

function canBeView(\$filename){
    switch (mime_content_type(\$filename)) {
        case 'image/gif':
        case 'image/jpeg':
        case 'image/jpg':
        case 'image/png':
        case 'imgage/bmp':
        case 'imgage/tiff':
        case 'imgage/svg+xml':
        case 'image/webm':
        case 'video/webm':
        case 'video/mpeg':
        case 'video/mp4':
        case 'video/mp4':
        case 'text/plain':
        case 'text/html':
        case 'text/css':
        case 'application/javascript':
        case 'application/pdf':
            return true;
    }
    return false;
}

\$path = \$_GET['path'] ? ('/'.\$_GET['path']) : '';
\$currpath = '${FILEROOT}' . \$path;

if (\$currpath == '') {
    die('currpath can not be empty string!');
}

if (is_file(\$currpath)) {
    if (canBeView(\$currpath)) {
        view(\$currpath);
    } else {
        dl(\$currpath);
    }
}

\$paths = glob(\$currpath.'/*');
echo '<meta charset=\"utf-8\">';
echo '<ul>';
foreach (\$paths as \$p) {
    if (\$p == '..' || \$p == '.') {
        continue;
    }
    \$name = preg_replace('#^' . str_replace('.', '\.', \$currpath) . '/?(.+)#', '\$1', \$p);
    \$patharg = preg_replace('#^' . str_replace('.', '\.', '${FILEROOT}') . '/?(.+)#', '\$1', \$p);
    //echo \"\$path/\$p <br> \";
    echo '<li>';
    echo \"<a href=\\\"/?path={\$patharg}\\\">\$name</a>\";
    echo '</li>';
}
echo '</ul>';
" > ~/bin/phpserver/.filebrowser-daemon/index.php

php -S 0.0.0.0:$PORT -t ~/bin/phpserver/.filebrowser-daemon
