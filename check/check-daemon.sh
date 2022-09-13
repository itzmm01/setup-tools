#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ansible-version.sh
# Description: a script to check if ansible is installed on
# local host and version is equal or greater than required
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

if [ $# -lt 1 ]; then
    #输入的参数少于1个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <daemon>"
    print_log "INFO" "eg:$baseName sshd"
    exit 1
fi

function check_daemon() {

    systemctl list-units | awk '{print $1}' | grep "^${1}.service" > /dev/null
    if [[ $? -ne 0 ]]; then
        print_log "ERROR" "$1 is not a daemon!"
        exit 1
    else
        systemctl status $1 > /dev/null
        if [[ $? -ne 0 ]]; then
            print_log "ERROR" "daemon $1 is not running!"
            exit 1
        else
            print_log "INFO" "daemon $1 is running"
            return 0
        fi
    fi

}

########################
#     main program     #
########################

check_daemon "$1"
