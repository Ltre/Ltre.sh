#!/bin/bash
HOST=$1
PORT=$2
LOCALPATH=$3
REMOTEPATH=$4
sshpass -p "密码" rsync -avP -e "ssh -p ${PORT}"  "${LOCALPATH}"  用户名@${HOST}:"${REMOTEPATH}"