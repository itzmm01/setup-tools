#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-disk-number.sh
# Description: a script to check  hardware disk num
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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <disk_number>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 10"

}

# desc: check  hardware disk num
# input: disk_number
# output: 1/0
function check_disk_number(){

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    disk_mumber_flag=$1
    if [ $? -ne 0 ]; then
        print_log "ERROR" "parameter failed and check is legality"
        print_usage
        return 1
    fi

    #actual disk num
    os_disk_numbers=$(lsblk   | awk '{print $6}' | grep  disk  | wc -l)

    if [ $os_disk_numbers -ge $disk_mumber_flag ];then
        print_log "INFO" "hardware disk number is Ok."
        return 0
    else
        print_log "ERROR" "hardware disk number is not enough. Nok."
        return 1
    fi
}


########################
#     main program     #
########################
check_disk_number $*
