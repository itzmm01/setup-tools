#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-hdfs-namenode-status.sh
# Description: a script to monitor hdfs namenode status.
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


#desc: get hdfs status
hdfs_namenode_status()
{
    check_input "$@"
    status=$(curl -s $1/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus | jq '.beans[].State')
    if [ ! -n  "$status" ];then
        print_log "ERROR" "could not connect to hdfs."
        exit 1
    else
        echo "$status"
    fi
}

hdfs_namenode_status "$@"

