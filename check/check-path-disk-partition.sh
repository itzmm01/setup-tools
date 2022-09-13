#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-path-disk-partition.sh
# Description: a script to check if the required path is mounted
# on the required disk partition
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
    print_log "INFO" "Usage: $baseName <path> <disk-partition>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName /data /dev/sdb"
}

# desc: check if input is valid
check_input()
{
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two arguments are required."
        print_usage
        exit 1
    fi
}



main() {
    check_input "$@"
    path="$1"
    requiredPartition="$2"

    print_log "INFO" "Check patition of path ${path}"
    # 1. Does path exist?
    if [ ! -d "${path}" ] ; then
        print_log "ERROR" "Path ${path} does not exist"
        return 1
    fi

    # 2. Does partition exist?
    if ! fdisk -l "${requiredPartition}" >/dev/null 2>&1 ; then
        print_log "ERROR" "Partition ${requiredPartition} does not exist"
        return 1
    else
        print_log "INFO" "Required partition: ${requiredPartition}"
    fi

    # 3. Is partition correct?
    currentPartition=$(df "${path}" | sed 1d | awk '{print $1}')
    print_log "INFO" "Current partition: ${currentPartition}"
    if [ "${currentPartition}" != "${requiredPartition}" ] ; then
        print_log "ERROR" "Nok"
        return 1
    else
        print_log "INFO" "Ok"
    fi
}


########################
#     main program     #
########################
main "$@"
