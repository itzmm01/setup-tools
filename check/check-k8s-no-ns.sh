#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-k8s-no-ns.sh
# Description: a script to check if given namespaces do not
# exist in current k8s platform
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
    print_log "INFO" "Desc: Check if given namespaces do not exist in current k8s platform"
    print_log "INFO" "Usage: $baseName <namespace-list>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName ns-1"
    print_log "INFO" "  $baseName ns-1 ns-2"
}


function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "At least one argument is required."
        print_usage
        exit 1
    fi
}




function main()
{
    check_input "$@"
    print_log "INFO" "Check k8s namespaces"
    if command -v kubectl > /dev/null 2>&1 ; then
        isAllOk=0
        AllNs=$(kubectl get ns | awk 'NR>1{print $1}' )
        for ns in "$@"; do
            hasNs=$(echo "${AllNs}" | grep  "${ns}")
            if [ "${hasNs}" != "" ]; then
                print_log "ERROR" "Namespace ${ns} already exists"
                isAllOk=1
            else
                print_log "INFO" "Namespace ${ns} does not exist"
            fi
        done
        if [ "${isAllOk}" == "1" ]; then
            print_log "ERROR" "Nok"
            return 1
        else
            print_log "INFO" "Ok"
        fi
        
    else
        print_log "ERROR" "kubectl command is not found in system env. Nok"
        return 1
    fi
        
}


########################
#     main program     #
########################
main "$@"
