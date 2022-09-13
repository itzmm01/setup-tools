#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-tz.sh
# Description: a script to set timezone
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
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <timezone>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName Asia/Shanghai"
        exit 1
    fi
}
# desc: set timezone
# input: tz_name
# output: 1/0
set_timezone() {
    check_input "$@"
    echo "$@"
    local tz_name="$1"
    timedatectl set-local-rtc 0 >/dev/null 2>&1
    if timedatectl set-timezone "$tz_name"; then
        print_log "INFO" "OK"
        return 0
    fi
    print_log "ERROR" "Nok"
    return 1
}


########################
#     main program     #
########################
set_timezone "$@"
