#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-gpu-model.sh
# Description: a script to check  gpu version on current machine
# meets requirement
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
baseName=$(basename $0)

# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName P40"

}

# desc: check if gpu model is ok
# input: model
# output: 1/0

#8路
#nvidia-smi --query-gpu=name,driver_version,count  --format=csv,noheader|head -1|awk -F',' '{print $1}'|awk '{print $2}'

check_gpu_model() {
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
    local require_ver=$1
    print_log "INFO" "Check if gpu version is ok."
    # check if gpu version is valid
    # get  gpu version on current machine
    cur_ver=$(nvidia-smi --query-gpu=name,driver_version,count  --format=csv,noheader|head -1|awk -F',' '{print $1}'|awk '{print $2}')
    if [[ -n $cur_ver ]]; then
        print_log "ERROR" "gpu model is not ok, cannot get model"
        return 1
    fi
    if [[ $cur_ver == $require_ver ]]; then
        print_log "INFO" "gpu model is ok,  Currently is  $cur_ver"
        return 0
    fi
    print_log "ERROR" "gpu model is not ok,  Currently $cur_ver"
    return 1
}

########################
#     main program     #
########################
check_gpu_model $1
