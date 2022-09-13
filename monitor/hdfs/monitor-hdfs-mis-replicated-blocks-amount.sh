#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-hdfs-mis-replicated-blocks-amount.sh
# Description: a script to monitor hdfs mis replicated blocks amount.
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

#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
#desc: get hdfs mis-replicated blocks amount.
hdfs_mis_replicated_blocks_amount()
{
    check_command hdfs
    num=$(curl -s $1/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | jq '.beans[].MissingReplOneBlocks' )
    if [ ! -n  "$num" ];then
        print_log "ERROR" "could not connect to hdfs."
        exit 1
    else
        echo "$num"
    fi
}

hdfs_mis_replicated_blocks_amount "$@"

