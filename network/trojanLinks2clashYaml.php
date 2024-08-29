<?php

function convert_trojan_to_clash($trojan_links) {
    $clash_config = "";

    $links = explode("trojan://", $trojan_links);
    foreach ($links as $link) {
        // 忽略可能出现的空字符串
        if (empty($link)) {
            continue;
        }

        $parts = explode("@", $link);
        $password = $parts[0];
        $server_info = explode("?", $parts[1])[0];
        $server_info = explode(":", $server_info);
        $server_address = $server_info[0];
        $server_port = $server_info[1];

        $clash_config .= "- { name: Trojan-GFW, type: trojan, server: $server_address, port: $server_port, password: $password }\n";
    }

    return $clash_config;
}

// 原始的 Trojan-GFW 链接列表，假设它们没有换行
$trojan_links = file_get_contents("trojan.links");

// 转换为 Clash 配置文件格式
$clash_config = convert_trojan_to_clash($trojan_links);

// 保存 Clash 配置文件
file_put_contents("clash_config.yaml", $clash_config);
