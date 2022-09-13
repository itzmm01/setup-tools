#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-service-running.sh
# Description: a script to check  service  running
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
# desc: print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName docker"
}
#desc: check input
check_input()
{
    if [ $# -ne 1 ];then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found"
       exit 1
    fi
}
#desc: get service status
function check_servcie(){
    check_command systemctl
    check_input "$@"
    print_log "INFO" "Check service $1 running."
    check_running=$(systemctl  status  $1  | grep Active | awk '{print " service is "$2,$3}')
    state=$(echo $check_running | grep -i running)
    if [[ -z "$state" ]];then
       print_log "ERROR" "Nok,$1 not running."
       return 1
    else
       print_log  "INFO" "ok"
    fi
}
check_servcie "$@"
