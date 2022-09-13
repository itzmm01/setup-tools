#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-set-netcard-mtu.sh
# Description: a script to set netcard mtu
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
    print_log "INFO" "Usage: $baseName <netcard-device-name> <mtu-value>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName eth0 1400"
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
    #set dev_name mtu_value
    mtu_value=$(ifconfig "${dev_name}"|grep mtu|awk '{print $NF}')
    if [ $mtu_value -ne  $comparison_value ];then
        ifconfig "${dev_name}" mtu ${comparison_value}
        if [ $? -ne 0 ];then
            print_log  "ERROR"  "Nok, $dev_name set mtu $comparison_value failed"
            return 1
        fi
    fi
    nic_ifconf="/etc/sysconfig/network-scripts/ifcfg-"${dev_name}
    if [ ! -f "$nic_ifconf" ]; then
        print_log  "ERROR"  "Nok, $nic_ifconf does not exist"
        return 1
    fi
    sed -i '/MTU=/d' "$nic_ifconf"
    echo -e "MTU=${comparison_value}" >> "$nic_ifconf"
    if [ $? -ne 0 ];then
        print_log  "ERROR"  "Nok, $dev_name set mtu $comparison_value $nic_ifconf failed"
        return 1
    fi
    print_log "INFO" "Ok. $dev_name set mtu $comparison_value"
    return 0
}
########################
#     main program     #
########################
main $@