#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-k8s-node-status.sh
# Description: a script to check  k8s node all ready
################################################################
# name of script
baseName=$(basename $0)
#desc:print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc: desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
# get k8s node status
main()
{
    check_command kubectl
    node_count=$(kubectl get node --no-headers|wc -l)
    if [[ $node_count -eq 0 ]];then
         error_msg=$(kubectl get node --no-headers)
         print_log "$ERROR" "Nok $error_msg"
         return 1  
    fi
    count=$(kubectl get node --no-headers| grep  "NotReady"|  wc -l)
    if [[ $count -eq 0 ]];then
         print_log "INFO" "OK, all node status:Ready" 
    else
        error_node_info=$(kubectl get node --no-headers| grep -"NotReady")
        print_log "ERROR" "Nok, node status has: NoReady"
        echo "$error_node_info"
        return 1
    fi
}
########################
#     main program     #
########################
main 
