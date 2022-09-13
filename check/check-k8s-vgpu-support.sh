#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-k8s-vgpu-support.sh
# Description: a script to check if a k8s node supports vgpu 
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
    print_log "INFO" "Desc: Check if a given k8s node supports vgpu"
    print_log "INFO" "Usage: $baseName <k8s-node-name>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 10.0.X.X"
    print_log "INFO" "  $baseName k8s-node-1"
}


function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Extactly one argument is required."
        print_usage
        exit 1
    fi
}




function main()
{
    check_input "$@"
    k8snode="$*"
    print_log "INFO" "Check k8s vgpu support on node ${k8snode}"
    if command -v kubectl > /dev/null 2>&1 ; then
        if kubectl get node "${k8snode}"  >/dev/null 2>&1 ; then
            vCudaCore=$(kubectl get node "${k8snode}" -o yaml | grep "vcuda-core")
            vCudaMemory=$(kubectl get node "${k8snode}" -o yaml | grep "vcuda-memory")
            if [[ "${vCudaCore}" != "" ]] && [[ "${vCudaMemory}" != "" ]] ; then
                print_log "INFO" "vcuda-core and vcuda-memory resources found. Ok"
            else
                print_log "ERROR" "vcuda-core or vcuda-memory resources not found. Nok"
                return 1
            fi
        else
            print_log "ERROR" "k8s node name {k8snode} is invalid. Valid node names are as below: "
            kubectl get node
            return 1
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
