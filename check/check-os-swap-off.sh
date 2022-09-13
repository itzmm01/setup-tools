#!/bin/bash

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
baseName=`basename $0`

# desc: check if os swap is off
# output: 1/0
function check_os_swap()
{
    # actual swap space
    swap_total=$(free -m|grep Swap|awk '{print $2}')
    if [[ $swap_total -eq 0 ]];then
        print_log "INFO" "swap is off"
        return 0
    else
        print_log "INFO" "swap is on"
        return 1
    fi
}


check_os_swap
