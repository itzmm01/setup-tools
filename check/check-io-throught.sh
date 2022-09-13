#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: 
# Description: a script to check disk io
# local host and version is equal or greater than required
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
export LANG=en_US.UTF-8
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")


if [ $# -lt 1 ]; then
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <seed>(MB/s)"
    print_log "INFO" "eg:$baseName 30"
    exit 1
fi


main(){
    io_seed=$(dd if=/dev/zero of=test bs=1024k count=4k conv=fsync oflag=direct,nonblock 2>&1 |tail -1|awk -F ',' '{print $NF}'|awk  '{print $1}')
	rm -f test
    need_seed="$1"
    if [ `echo "$io_seed > $need_seed" | bc` -eq 1 ]; then
        echo "current: $io_seed"
        exit 0
    else
        echo "current: $io_seed, need: $need_seed"
        exit 1
    fi
}

main $@
