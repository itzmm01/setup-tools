#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mysql-global-status.sh
# Description: a script to monitor mysql global status. 
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
    print_log "INFO" "    $baseName 192.168.X.X 3306 root root123"
}
#dsec: check input
function check_input()
{
    if [ $# -ne 5 ]; then
        print_log "ERROR" "Exactly four argument is required."
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
#desc: get mysql global status
mysql_global_status()
{
    check_command mysql
    check_input "$@"
    status=$(mysql -h $1 -P $2 -u$3 -p$4 -e "show global status like '$5';"|grep "$5"|awk '{print $2}')
    if [ ! -n  "$status" ];then
        print_log "ERROR" "could not connect to mysql or status does not exist."
        exit 1
    else 
        echo "$status"
    fi
}

mysql_global_status "$@"

