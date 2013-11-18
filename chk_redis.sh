#!/bin/bash
REDIS_PORT=$1
REDIS_BIN_DIR="/usr/local/redis/bin/"

log() {
   logger  -id "$*"
}
logf() {
 echo >>/var/log/redis/redis.chk.log `date  "+%F %T"` "$*"
}
${REDIS_BIN_DIR}/redis-cli  -h 127.0.0.1 -p ${REDIS_PORT} info >>/tmp/redis/redis.${REDIS_PORT}.info

if [ "$?" != "0" ];then logf "redis ${REDIS_PORT} error" ;exit 1; else logf "redis ${REDIS_PORT} ok" ;exit 0 ;fi
