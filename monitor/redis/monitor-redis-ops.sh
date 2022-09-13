#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-redis-ops.sh
# Description: a script to monitor redis ops. 
################################################################
# name of script
baseName=$(basename $0)
#desc: print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc；print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName 192.168.X.X 6379 password"
}
#dsec: check input
function check_input()
{
    if [ $# -ne 3 ]; then
        print_log "ERROR" "Exactly three argument is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
#desc: get redis ops
redis_ops()
{
    check_command redis-cli
    check_input "$@"
    ops=$(redis-cli -h $1 -p $2 -a $3 info|grep "instantaneous_ops_per_sec")
    if [ ! -n  "$ops" ];then
        print_log "ERROR" "could not connect to redis."
        exit 1
    else 
        ops=$(echo $ops | cut -d \: -f 2)
        echo "$ops"
    fi
}

redis_ops "$@"

