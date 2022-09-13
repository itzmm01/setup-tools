#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-netcard-speed.sh
# Description: a script to check  netcard speed on current machine
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

function is_int()
{
    str=$1

    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        return 1
    fi

    print_log "INFO" "Check if $str is a valid positive integer."
    if [[ $str =~ ^[+-]?[0-9]+$  ]]; then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "ERROR" "Nok."
        return 1
    fi
}


# name of script
baseName=$(basename $0)

# desc: print how to use
function print_usage(){
    print_log "INFO" "Usage: $baseName <netcard_name> <speed>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName eth0 10000Mbs"
}

# desc: check if netcard speed is ok
# input: netcard_speed
# output: 1/0
function check_netcard_speed(){
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two parameter is required."
        print_usage
        return 1
    fi
    netcard_name_flag=$1
    if ! ip a|grep $netcard_name_flag >/dev/null 2>&1; then
        print_log "ERROR" "$netcard_name_flag not found"
        return 1
    fi
    netcard_speed_flag=$2
    if ! echo $netcard_speed_flag|grep -i Mbs >/dev/null 2>&1; then
        print_log "ERROR" "parameter is not ok ,need Mbs"
        print_usage
        return 1
    fi
    netcard_speed_flag=${netcard_speed_flag%M*}
    print_log "INFO" "Check if netcard speed is ok."
    # get  netcard speed on current machine
    netcard_speed=`ethtool $netcard_name_flag|grep Speed |awk -F '[ M]+' '{print $2}'`
    if ! is_int $netcard_speed; then
        print_log "ERROR" "get current machine wrong,not int"
        return 1
    fi
    retcode=$(awk -v  ver1=$netcard_speed_flag -v ver2=$netcard_speed  'BEGIN{print(ver2>=ver1)?"0":"1"}')
    if [ $retcode -eq 0 ]; then
        print_log "INFO" "check netcard speed  Ok"
        return 0
    fi
    print_log "ERROR" "check netcard speed Nok"
    return 1
}

########################
#     main program     #
########################
check_netcard_speed $*
