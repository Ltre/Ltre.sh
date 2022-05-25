#!/bin/bash

HOST=$1
PORT=$2
REMOTEPATH=$3
LOCALPATH=$4
sshpass -p "远程机器密码" rsync -av -e "ssh -p ${PORT}" abc@${HOST}:${REMOTEPATH}  "${LOCALPATH}"
