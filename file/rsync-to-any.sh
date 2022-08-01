#!/bin/bash

read -p "Input ssh password:" PASSWD

if [ ! $PASSWD ]; then
    echo "password must be required!"
    exit
fi

HOST=$1
PORT=$2
LOCALPATH=$3
REMOTEPATH=$4
sshpass -p "${PASSWD}" rsync -avP -e "ssh -p ${PORT}"  "${LOCALPATH}"  用户名@${HOST}:"${REMOTEPATH}"
