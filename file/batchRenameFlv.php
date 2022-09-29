#!/usr/local/php/bin/php
<?php
/**
 * 批量去除B站录播文件名中的空白字符（换行、空格）
 */

$files = glob('*.flv'); //在centos7/8中证实，glob拿到的列表顺序，跟ls -l得到的无异
//usort($files, function($a, $b){
//    return filemtime($b) - filemtime($a);//filemtime得到的顺序还是乱的，并非真的完全按时间排序
//});
foreach ($files as $k => $v) {
  $to = "RN{$k}_".preg_replace('/\s/', '', $v);
  rename($v, $to);
  echo "{$v}\n => {$to} ###\n\n";
  sleep(1);
}

