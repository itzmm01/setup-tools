#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-elasticsearch-number-of-data-nodes.sh
# Description: a script to monitor elasticsearch number_of_data_nodes.
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
#desc: get elasticsearch number_of_data_nodes
elasticsearch_number_of_data_nodes()
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
    data=$(curl -s http://${ip}:${port}/_cluster/health --header "Authorization: Basic ${auth}" |jq '.number_of_data_nodes')
    echo "$data"
}

elasticsearch_number_of_data_nodes "$@"

