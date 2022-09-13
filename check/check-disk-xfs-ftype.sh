#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-disk-xfs-ftype.sh
# Description: a script to check disk xfs ftype
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
    currentTime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path|dev_name>"
    print_log "INFO" "e.g.: $baseName /data"
    print_log "INFO" "e.g.: $baseName /dev/vdb"
}


# check input
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Exactly 1 argumnets are required"
        print_usage
        exit 1
    fi
}

# desc: check disk ftype
# input: none
# output: 1/0
function check_disk_ftype()
{
    check_input "$@"
    path="$1"
    if [ -b "${path}" -o -d "${path}" ]; then
        # get current fs type
        if command -v xfs_info >/dev/null 2>&1; then
            cur_ftype=$(xfs_info $path 2>/dev/null| grep ftype|awk -F "ftype=" '{print $NF}')
            if [ "$cur_ftype" = "1" ];then
                print_log "INFO" "Ok，current disk ftype is 1"
                return 0
            fi
            print_log "ERROR" "Nok，current disk ftype is 0"
            return 1
        fi
        print_log "ERROR" "xfs_info command is not found in system env"
        return 1
    fi
    print_log ERROR "$path not a block device or $path path does not exist."
    return 1
}

########################
#     main program     #
########################
check_disk_ftype "$@"
