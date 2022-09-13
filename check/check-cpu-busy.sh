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
    print_log "INFO" "Usage: $baseName <threshold>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 8"

}

# desc: check if cpu core is ok
# input: threshold, operator
# output: 1/0
function check_threshold()
{

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    threshold=$1

    # check if threshold is valid
    # is it an integer?
    if ! is_int $threshold >/dev/null 2>&1 ; then
        print_log "ERROR" "Input \"$threshold\" is not valid. Only integer is allowed."
        print_usage
        return 1
    fi

    # get total cpu core number on current machine
    cpuBusy=$(cat /proc/stat|grep 'cpu '|awk '{print $1+$2+$3+$4+$5+$6+$7+$8+$9+$10,$5}' > /tmp/$USER/cpu_s;
             sleep 1;
             cat /proc/stat|grep 'cpu '|awk '{print $1+$2+$3+$4+$5+$6+$7+$8+$9+$10,$5}' > /tmp/$USER/cpu_e;
             pr -m -t /tmp/$USER/cpu_s /tmp/$USER/cpu_e|awk '{print ($4-$2)*100/($3-$1)}'|awk '{print 100-int($1)}')
    if [[ $cpuBusy -le $threshold ]];then
        print_log "INFO" "获取CPU使用率当前值: $cpuBusy %, 处于合理阈值之内: $threshold %."
        return 0
    else
        print_log "ERROR" "获取CPU使用率当前值: $cpuBusy %, 大于合理阈值: $threshold %."
        return 1
    fi
}


########################
#     main program     #
########################
check_threshold $*
