#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-umount-path.sh
# Description: a script to umount disk
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path>"
    print_log "INFO" "  init-umount-disk:  path"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  /data"
}

check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

# desc: umount disk
# input: path
# output: 1/0
function main()
{
    check_input "$@"
    local mnt_path="$1"
    mnt_path_status=$(df -P | grep "$mnt_path$")
    mnt_path_fstab=$(grep "$mnt_path" /etc/fstab|awk '{print $1,$2}'|grep "$mnt_path$"|awk '{print $1}'|grep -v ^#|head -n 1)
    # check mnt_path_fstab and mnt_path_status
    if [[ ! -n "$mnt_path_status" ]] && [[ ! -n "$mnt_path_fstab" ]];then
       print_log "INFO" "$mnt_path path not mount"
       return 0
    fi
    # set umount disk $mnt_path
    if [[ -n "$mnt_path_status" ]];then
        umount "$mnt_path" 
        if [[ $? -eq 0 ]];then
            print_log "INFO" "umount disk $mnt_path: ok"
        else
            print_log "ERROR" "umount disk $mnt_path: fail"
            return 1
        fi
    fi
    # set umount disk $mnt_path to fstab
    if [[ -n "$mnt_path_fstab" ]];then
        sed -i "s|^$mnt_path_fstab|#$mnt_path_fstab|g" /etc/fstab 
        if [[ $? -eq 0 ]];then
            print_log "INFO" "umount disk $mnt_path to fstab: ok"
            return 0
        fi
        print_log "ERROR" "umount disk $mnt_path to fstab: fail"
        return 1
    fi
}
########################
#     main program     #
########################
main "$@"
