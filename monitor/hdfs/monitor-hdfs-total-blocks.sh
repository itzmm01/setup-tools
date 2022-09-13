#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-hdfs-total-blocks.sh
# Description: a script to monitor hdfs total blocks.
################################################################
baseName=$(basename $0)
#desc: print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
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

#desc；print how to use
print_usage()
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName http://192.168.X.X:9870"
}

#desc: get hdfs total blocks.
hdfs_total_blocks()
{
    check_input "$@"
    num=$(curl -s $1/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | jq '.beans[].BlocksTotal' )
    if [ ! -n  "$num" ];then
        print_log "ERROR" "could not connect to hdfs."
        exit 1
    else
        echo "$num"
    fi
}

hdfs_total_blocks "$@"

