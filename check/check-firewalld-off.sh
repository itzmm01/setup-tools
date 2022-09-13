#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-firewalld.sh
# Description: a script to check if firewalld is disabled
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

# desc: check firewalld
# input: none
# output: 1/0
function check_firewalld()
{

    print_log "INFO" "Check firewalld."
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    if [ "$os_version" == "uos" ]; then
        print_log "INFO" "Ok."
        exit 0
    fi
    checkRunning=$(firewall-cmd --state 2>&1 | grep "not running")
    if [ "$checkRunning" == "" ];then
        print_log "ERROR" "Failed."
        return 1
    else
        print_log "INFO" "Ok."
    fi

    return 0

}


########################
#     main program     #
########################
check_firewalld
