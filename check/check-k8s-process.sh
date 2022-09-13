#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-k8s-node-process.sh
# Description: check if k8s node processes are running
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")


# desc: print how to use
print_usage() {
    print_log "INFO" "Desc: Check if k8s related processes are running on k8s nodes"
    print_log "INFO" "Usage: $baseName"
}


# main
function main()
{

    print_log "INFO" "Check k8s releated processes status"
    procList=("kubelet" "kube-proxy")
    isAllOk=0
    for process in ${procList[*]}; do
        pid=$(pgrep "${process}")
        if [ "${pid}" != "" ]; then
            print_log "INFO" "Process ${process} is running with below pid(s):"
            echo "${pid}"
        else
            print_log "ERROR" "Process ${process} is not running"
            isAllOk=1
        fi
    done
    
    return ${isAllOk}
}


########################
#     main program     #
########################
main "$@"
