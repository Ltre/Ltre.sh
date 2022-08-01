#!/bin/bash

read -p "Input password:" PWD_GZZ
if [ ! $PASSWD ]; then
        echo "password is null!"
        exit
fi


HOST=$1
PORT=$2
REMOTEPATH=$3
LOCALPATH=$4
sshpass -p "远程机器密码" rsync -avP -e "ssh -p ${PORT}" 用户名@${HOST}:"${REMOTEPATH}"  "${LOCALPATH}"
