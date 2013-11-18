#!/bin/bash
#
LOCAL_IP="$(ifconfig bond0 | grep -w inet | awk '{ print $2 }' | awk -F: '{ print $2 }')"
if [ "${LOCAL_IP}" == "localip" ]; then 
	REDIS_MASTER_IP="masterip";
elif [ "${LOCAL_IP}" == "localip" ];then
 	REDIS_MASTER_IP="masterip"
else
  echo "error"
  exit 1
fi

REDIS_PORT="6380 6381"
REDIS_BIN_DIR="/usr/local/redis/bin/"

chk_redis_alive () {
	alive=$(${REDIS_BIN_DIR}/redis-cli  -h 127.0.0.1 -p ${REDIS_PORT} ping)
	if [ "$alive" != "PONG" ]; then exit 1;fi
}

# parse argv moudle
for arg in "$@";do
        case $arg in
        -m) arg_m=true;;
        -s) arg_s=true;;
        *) exit 1;;
        esac
done

# log sub module 
log() {
 logger  -id "$*"
}

start_master() {
     for port in ${REDIS_PORT};do
         cmdsetmaster="${REDIS_BIN_DIR}/redis-cli -h "127.0.0.1" -p ${port} SLAVEOF no one"
         #${cmdsetmaster} >/dev/null ;
        a=1
         while [ "x${state}" != "xmaster" ];do
             ${cmdsetmaster} >/dev/null ;
            #${REDIS_BIN_DIR}/redis-cli -h "127.0.0.1" -p 6381 SLAVEOF  192.168.2.163  6381 >>/dev/null
              state=$(${REDIS_BIN_DIR}/redis-cli -h 127.0.0.1 -p ${port} info|awk  -F ':' '/role/ {print $NF}'|tr -d "\r");
              if [ ${a} -eq 5 ];then
                /etc/init.d/redis_${port} restart >>/dev/null
                [ $? -eq 0 ]&& msg="restart redis-server on ${port} sucessed";${cmdsetmaster} >/dev/null|| msg="tried restart redis-server on ${port} faild"
                log "Promoting redis-server to MASTER on ${port} Faild 3 times, ${msg}"
              fi
              state=$(${REDIS_BIN_DIR}/redis-cli -h 127.0.0.1 -p ${port} info|awk  -F ':' '/role/ {print $NF}'|tr -d "\r")
              ((++a))
        done
         log "Promoting redis-server to MASTER on ${port} SUCESS"
         state=""
   done
}

start_slave() {
     for port in ${REDIS_PORT};do
        ${REDIS_BIN_DIR}/redis-cli -h "127.0.0.1" -p ${port}  SLAVEOF ${REDIS_MASTER_IP} ${port}
	[ $? -eq 0 ]&&log "Promoting redis-server to Slave on ${port} SUCESS" ||log "Promoting redis-server to Slave on ${port} Faild"
     done
}



if [ $arg_m ]; then
       # log "Promoting redis-server to MASTER"
        start_master
elif [ $arg_s ]; then
        #log "Promoting redis-server to SLAVE"
        start_slave
else
	log "some errors"
        exit 1
fi
