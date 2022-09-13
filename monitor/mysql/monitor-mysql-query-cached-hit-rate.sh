#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mysql-query_cached-hit-rate.sh
# Description: a script to monitor mysql query cached hit rate 
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
    if [ $# -ne 4 ]; then
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
#desc: get mysql query cached hit rate
mysql_query_cached_hit_rate()
{
    check_command mysql
    check_input "$@"
    hitRate=""
    hits=$(mysql -h $1 -P $2 -u$3 -p$4 -e "show status  like 'Qcache_hits';"|grep 'Qcache_hits'|awk '{print $2}')
    if [ ! -n  "$hits" ];then
        print_log "ERROR" "could not connect to mysql."
        exit 1
    else 
        inserts=$(mysql -h $1 -P $2 -u$3 -p$4 -e "show status  like 'Qcache_inserts';"|grep 'Qcache_inserts'|awk '{print $2}')
        if [ $inserts -eq 0 ];then
           if [ $hits -eq 0 ];then
                print_log "INFO" "Qcache_hits and Qcache_inserts is zero."
                exit 1
           fi
        fi
        hitRate= $(echo "scale=2; ($hits / ($hits + $inserts))*100" | bc)
        echo "$hitRate"
    fi
    
}

mysql_query_cached_hit_rate "$@"

