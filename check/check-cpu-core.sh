#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-cpu-core.sh
# Description: a script to check if cpu core on current machine
# meets requirement
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
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
    print_log "INFO" "Usage: $baseName <cpu_core>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 8"

}

# desc: check if cpu core is ok
# input: cpu_core, operator
# output: 1/0
function check_cpu_core()
{

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    cpu_core=$1

    # check if cpu_core is valid
    # is it an integer?
    if ! is_int $cpu_core >/dev/null 2>&1 ; then
        print_log "ERROR" "Input \"$cpu_core\" is not valid. Only integer is allowed."
        print_usage
        return 1
    fi
    print_log "INFO" "check cpu core num is ok."
    # get total cpu core number on current machine
    cpuCoreNum=`cat /proc/cpuinfo | grep "processor" | sort -u | wc -l`
    if [[ $cpuCoreNum -ge $cpu_core ]];then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "ERROR" "Nok,Current: $cpuCoreNum, required: $cpu_core."
        return 1
    fi
}


########################
#     main program     #
########################
check_cpu_core $*
