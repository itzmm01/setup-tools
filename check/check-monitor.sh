#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-monitor.sh
# Description: script monitor-*.sh  results less than define value
################################################################
# get work directory
workDir=$(cd "$(dirname "$0")" || exit; pwd)
monitorDir=$(cd "$workDir/../monitor" || exit; pwd)
# name of script
baseName=$(basename $0)
#desc:print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc: print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <script> <comparison_value> [comparison_key]"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName cpu/monitor-cpu-1minute-avg.sh 1"
    print_log "INFO" "    $baseName disk/monitor-disk-util.sh 95 vda"
}
#desc: check input
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "ERROR" "At least two argument is required."
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
#desc: check monit
check_monitor()
{
    check_input "$@"
    monitor_script="$monitorDir/$1"
    if ! [ -f $monitor_script ];then
        print_log "ERROR" "Nok,$monitor_script not exist."
        return 1
    fi
    comparison_value=$2
    is_int $comparison_value
    monitor_result=$(sh "$monitor_script" $3)
    monitor_flag=$(echo $monitor_result | grep -i "ERROR")
    if [[ "$monitor_flag" != "" ]];then
        echo "$monitor_result"
        return 1
    fi
    compare_result=$(echo "$monitor_result <= $comparison_value" |bc)
    if [[ $compare_result -eq 0 ]];then
        print_log "ERROR" "Nok,Current:${monitor_result}, required less: ${comparison_value}"
        return 1
    else
        print_log "INFO" "Ok,Current:${monitor_result}, required less: ${comparison_value}"
    fi
}
########################
#     main program     #
########################
check_monitor "$@"