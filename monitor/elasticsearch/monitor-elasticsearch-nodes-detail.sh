#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-elasticsearch-nodes-detail.sh
# Description: a script to monitor elasticsearch nodes  detail.
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
    print_log "INFO" "    $baseName 192.168.X.X 9200 user password"
}
#dsec: check input
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "ERROR" "At least two argument is required."
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
#desc: get elasticsearch nodes detail
elasticsearch_nodes_detail()
{
    check_input "$@"
    ip=$1
    port=$2
    user=$3
    password=$4
    auth=$user:$password
    auth=$(echo -n $user:$password |base64)
    esStatus=$(curl -s -m 5 -IL http://${ip}:${port} --header "Authorization: Basic ${auth}"|grep 200)
    if [ "$esStatus" == "" ];then
        print_log "ERROR" "could not connect to elasticsearch."
        exit 1
		fi
    info=$(curl -s http://${ip}:${port}/_nodes/stats --header "Authorization: Basic ${auth}" |jq '.indices.segments.count')
    echo "$info"
}

elasticsearch_nodes_detail "$@"

