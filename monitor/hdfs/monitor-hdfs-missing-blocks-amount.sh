#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-hdfs-missing-blocks-amount.sh
# Description: a script to monitor hdfs missing blocks amount.
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

#desc: get hdfs missing blocks.
hdfs_missing_blocks_amount()
{
    check_input "$@"
    num=$(curl -s $1/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | jq '.beans[].MissingBlocks' )
    if [ ! -n  "$num" ];then
        print_log "ERROR" "could not connect to hdfs."
        exit 1
    else
        echo "$num"
    fi
}

hdfs_missing_blocks_amount "$@"

