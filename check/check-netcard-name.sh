#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-network-name.sh
# Description: a script to check if network arch on current machine
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename $0)
# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <device-name>"
    print_log "INFO" "  check_netcard_name:  device-name"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  eth0"
    print_log "INFO" "  $baseName  eth0,eth1"
}
# check input
check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}
#desc: print cpu arch Is the expectation met
#input: network_name
#ouput: 0/1
check_netcard_name(){
    check_input $@
    dev_name=$1
    dev_name_arr=(${dev_name//,/ })
	if [ -f /proc/net/dev ]; then
        for dev_name_item in "${dev_name_arr[@]}" ; do
            if  sed '1,2d' /proc/net/dev | awk -F ':' '{print $1}' | grep -w "${dev_name_item}"  >/dev/null 2>&1; then
                 print_log  "INFO"  "Ok."
                 return 0
            fi            
        done    
        print_log  "ERROR"  "Nok."
        return 1
	fi
	print_log  "ERROR"  "Nok."
    return 1
}
########################
#     main program     #
########################
check_netcard_name $@
