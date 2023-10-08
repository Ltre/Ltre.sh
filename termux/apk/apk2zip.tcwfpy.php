#!/data/data/com.termux/files/usr/bin/php
<?php

$files = glob('*.apk'); //在centos7/8中证实，glob拿到的列表顺序，跟ls -l得到的无异
$zip = new ZipArchive;
foreach ($files as $v) {
  $to = $v.'.tcwfpy.zip';
  $cmd = "zip -r -P 密码 \"{$to}\" \"{$v}\" ";
  system($cmd);
  unlink($v);
}

