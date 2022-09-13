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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path> <fs_type>"
    print_log "INFO" "e.g.: $baseName /data ext3"
    print_log "INFO" "      $baseName /test ext4,xfs"

}

# check input
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "ERROR" "Exactly 2 argumnets are required"
        print_usage
        exit 1
    fi
}

main()
{
    check_input "$@"
    path=$1
    fstypes=$2

    if [ ! -d "${path}" ] ; then
        print_log "ERROR" "$path does not exist"
        return 1
    fi


    fstypes_arr=(${fstypes//,/ })

    # get current fs type
    cur_fstype=$(df -Th "${path}" | tail -1 | awk '{print $2}')
    print_log "INFO" "Check fs type of path $path"
    print_log "INFO" "FS type: current: ${cur_fstype}, required: ${fstypes}"

    # check if current fs type matches any of those required
    for fstype in "${fstypes_arr[@]}" ; do
        if [ "${cur_fstype}" == "${fstype}" ]; then
            print_log "INFO" "Ok"
            return 0
        fi
    done

    print_log "ERROR" "Nok"
    return 1

}

main "$@"
