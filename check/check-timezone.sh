#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-timezone.sh
# Description: a script to check if timezone on current machine
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
baseName=`basename $0`


# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <time_zone>"
    print_log "INFO" "  <time_zone>: required timezone, e.g. Asia/Shanghai, America/Vancouver, ..."
    print_log "INFO" "Example: $baseName Asia/Shanghai"
}

# desc: check if timezone is ok
# input: time_zone
# output: 1/0
function check_timezone()
{

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    print_log "INFO" "Check if timezone is ok."
    time_zone=$1
    #time_zone=$(to_lower $time_zone)

    currentTimezone=$(timedatectl status | grep "Time zone" | awk -F":" {'print $2'} | sed 's/ //g' | awk -F"(" {'print $1'})
    #currentTimezone=$(to_lower $currentTimezone)
    print_log "INFO" "Current timezone: $currentTimezone, required timezone: $time_zone."
    if [ "$currentTimezone" == "$time_zone" ];then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "WARNING" "Nok."
        return 1
    fi
}


########################
#     main program     #
########################
check_timezone $*
