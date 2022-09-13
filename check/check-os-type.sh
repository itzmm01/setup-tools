#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-os-version.sh
# Description: a script to check if current os version on machine
# meet the given requirement
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

function print_usage()
{
    print_log "INFO" "Usage: ${baseName} <os-type>"
    print_log "INFO" "e.g. ${baseName} centos"
}

check_input()
{
    if [ $# -ne 1 ]; then
    #输入的参数少于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

check_os_type()
{
    check_input "$@"
    os_type=$1
    print_log "INFO" "Required OS type: ${os_type}"
    os_name=$(ls /etc/*-release |grep -Ewv "os|system" |awk -F'-|/' '{print $3}')
    echo "${os_name}" |grep -wqi  "${os_type}"
    if [ "$?"x != "0"x ];then
        print_log "ERROR" "Not supported OS type Nok"
        print_log "INFO" "Currently supported are as below" 
        echo "${os_name}"
        exit 1
    else
        print_log "INFO" "Supported OS type. Ok"
        exit 0
    fi
}

check_os_type "$@"
