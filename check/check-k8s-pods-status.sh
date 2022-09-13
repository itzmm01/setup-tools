#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-k8s-pod-status.sh
# Description: a script to check  k8s pod status is running
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
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
#desc: get pods status
main()
{
    check_command kubectl
    pod_count=$(kubectl get po --no-headers -A|awk '{print $1,$2,$3}'|awk -F "/" '{print $1,$2," ",$3}'|awk '{if($3 != $4){print "namespac:" $1,"pod_name:" $2}}'| wc -l)
    if [[ $pod_count -eq 0 ]];then
        print_log "INFO" "OK all pods status: Ready" 
        return 0
    fi
    erro_pod_info=$(kubectl get po --no-headers -A|awk '{print $1,$2,$3}'|awk -F "/" '{print $1,$2," ",$3}'|awk '{if($3 != $4){print "namespac: " $1,"pod_name: " $2}}')
    print_log "ERROR" "Nok pods status has: NoReady"
    echo "$erro_pod_info"
    return 1
}
########################
#     main program     #
########################
main 
