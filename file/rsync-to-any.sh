#!/bin/bash

read -p "Input password:" PWD_GZZ
if [ ! $PASSWD ]; then
        echo "password is null!"
        exit
fi


HOST=$1
PORT=$2
LOCALPATH=$3
REMOTEPATH=$4
sshpass -p "$PASSWD" rsync -avP -e "ssh -p ${PORT}"  "${LOCALPATH}"  用户名@${HOST}:"${REMOTEPATH}"

