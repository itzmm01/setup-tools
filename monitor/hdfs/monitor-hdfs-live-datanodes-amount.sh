#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-hdfs-live-datanodes-amount.sh
# Description: a script to monitor hdfs live datanodes amount.
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

#desc: get hdfs live datanodes amount
hdfs_live_datanodes_amount()
{
    check_input "$@"
    hdfsStatus=$(curl -s -m 5 -IL $1|grep 200)
    if [ "$hdfsStatus" == "" ];then
        print_log "ERROR" "could not connect to hdfs jmx."
        exit 1
		fi
    num=$(curl -s $1/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | jq '.beans[].NumLiveDataNodes' )
    if [ ! -n  "$num" ];then
        print_log "ERROR" "could not connect to hdfs."
        exit 1
    else
        echo "$num"
    fi
}

hdfs_live_datanodes_amount "$@"

