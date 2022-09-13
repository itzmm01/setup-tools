#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-gpu-driver.sh
# Description: a script to check  gpu driver version on current machine
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
baseName=$(basename "$0")

# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName <version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 390.44"

}

check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
}

# desc: check if gpu driver is ok
# output: 1/0

check_gpu_version() {
    check_input "$@"
    requiredVerion="$1"
    print_log "INFO" "Check if gpu driver version is ok."
    # check if gpu version is valid
    if command -v nvidia-smi >/dev/null 2>&1 ; then 
        # get gpu version on current machine
        cur_ver=$(nvidia-smi --query-gpu=name,driver_version,count  --format=csv,noheader|head -1|awk -F',' '{print $2}'|sed 's/ //g')
        if [ -z "${cur_ver}" ]; then
            print_log "ERROR" "Failed to get current gpu driver version. Nok"
            return 1
        fi
        print_log "INFO" "Current: ${cur_ver} , required: ${requiredVerion}"
        #与服务器版本做对比
        retcode=$(awk -v ver1="${requiredVerion}" -v ver2="${cur_ver}" 'BEGIN{print(ver1<=ver2)?"0":"1"}')
        if [ "${retcode}" == "0" ];then
            print_log "INFO" "Ok"
            return 0
        fi
        print_log "ERROR" "Nok"
        return 1
    else
        print_log "ERROR" "nvidia-smi command is not found in system env. Nok"
        return 1
    fi
}


########################
#     main program     #
########################
check_gpu_version "$@"
