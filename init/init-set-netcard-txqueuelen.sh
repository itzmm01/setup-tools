#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-set-netcard-txqueuelen.sh
# Description: a script to set netcard txqueuelen
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")
# desc: print how to use
function print_usage(){
    print_log "INFO" "Usage: $baseName <netcard-device-name> <txqueuelen-value>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName eth0 10000"
}
# desc: check input
function check_input(){
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two parameter is required."
        print_usage
        exit 1
    fi
}
#check int
function is_int()
{
    str=$1
    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        print_usage
        exit 1
    fi
    if [[ $str =~ ^[+-]?[0-9]+$  ]]; then
        return 0
    else
        print_log "ERROR" "Nok. Input Parameter must number type."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}
# desc: mount disk
# input: fs_type, dev_name, path, mount_option, fs_option
# output: 1/0
main(){
    #check
    check_input $@
    check_command ifconfig
    #set local var
    local dev_name="$1"
    local comparison_value=$2
    is_int ${comparison_value}
    #check dev_name
    if [ ! -f /proc/net/dev ]; then
        print_log  "ERROR"  "Nok, $dev_name does not exist"
        return 1
	fi
    #check dev_name
    if  ! sed '1,2d' /proc/net/dev | awk -F ':' '{print $1}' | grep -w "${dev_name}"  >/dev/null 2>&1; then
        print_log  "ERROR"  "Nok, $dev_name does not exist"
        return 1
    fi
    #set dev_name txqueuelen
    txqueuelen_value=$(ifconfig "${dev_name}"|grep txqueuelen|awk '{print $(NF-1)}')
    if [ $txqueuelen_value -ne  $comparison_value ];then
        ifconfig "${dev_name}" txqueuelen ${comparison_value}
        if [ $? -ne 0 ];then
            print_log  "ERROR"  "Nok, $dev_name set txqueuelen $comparison_value failed"
            return 1
        fi
    fi
    #set rc.local dev_name txqueuelen
    if [ ! -e /etc/rc.d/rc.local ]; then
        echo -e "\nifconfig "${dev_name}" txqueuelen ${comparison_value}" >> /etc/rc.d/rc.local
        if [ $? -ne 0 ];then
            print_log  "ERROR"  "Nok, $dev_name set txqueuelen $comparison_value /etc/rc.d/rc.local failed"
            return 1
        fi
	fi
    if ! grep -q "ifconfig[[:space:]]\+${dev_name}[[:space:]]\+txqueuelen[[:space:]]\+${comparison_value}" /etc/rc.d/rc.local;then
        echo -e "\nifconfig "${dev_name}" txqueuelen ${comparison_value}" >> /etc/rc.d/rc.local
        if [ $? -ne 0 ];then
            print_log  "ERROR"  "Nok, $dev_name set txqueuelen $comparison_value /etc/rc.d/rc.local failed"
            return 1
        fi        
    fi
    chmod +x /etc/rc.d/rc.local
    print_log "INFO" "Ok. $dev_name set txqueuelen $comparison_value"
    return 0
}
########################
#     main program     #
########################
main $@