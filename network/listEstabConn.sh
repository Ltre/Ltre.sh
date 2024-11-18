# 使用 ss 命令列出所有已建立的 TCP 连接
ss -t | grep ESTAB | awk '{
    # 按空格分割每一行，并提取本地地址和端口以及远程地址和端口
    split($4, local, ":");
    split($5, remote, ":");
    local_ip = local[1];
    local_port = local[2];
    remote_ip = remote[1];
    remote_port = remote[2];

    # 构建 IP 对的键，格式为 ip1-ip2
    ip_pair = local_ip "-" remote_ip;

    # 构建并存储端口对，格式为 local_port:remote_port
    port_pair = local_port ":" remote_port;

    # 使用数组收集同一 IP 对的所有端口对
    if (ip_pair in ports) {
        # 检查端口对是否已存在，避免重复
        if (!(port_pair in unique[ip_pair])) {
            ports[ip_pair] = ports[ip_pair] ", " port_pair;
            unique[ip_pair][port_pair] = 1;
        }
    } else {
        ports[ip_pair] = port_pair;
        unique[ip_pair][port_pair] = 1;
    }
}

END {
    # 输出所有 IP 对和对应的端口对集合
    for (pair in ports) {
        print pair " (" ports[pair] ")";
    }
}'
