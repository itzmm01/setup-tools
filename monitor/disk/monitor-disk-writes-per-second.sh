#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-disk-writes-per-second.sh
# Description: a script to monitor disk writes per second 
# meets requirement
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
    print_log "INFO" "    $baseName  vda"
}
#dsec: check input
function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
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
#desc: get disk writes per second
disk_writes_per_second()
{
    check_command iostat
    check_input "$@"
    used=""
    count=$(iostat | grep "$1" | wc -l)
    if [[ $count -eq 0 ]]; then
        print_log "ERROR" "disk:$1 not exist."
        exit 1
    else
         used=$(iostat -x | grep "$1" | awk '{print $3}')
         echo $used
    fi
}

disk_writes_per_second "$@"

