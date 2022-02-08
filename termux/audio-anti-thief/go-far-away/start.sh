CUR_DIR=$(cd `dirname $0` && pwd -P)
nohup ${CUR_DIR}/maintainVolume.sh > ${CUR_DIR}/../maintain.log & 
nohup ${CUR_DIR}/maintainPlay.sh > ${CUR_DIR}/../maintain.log &


