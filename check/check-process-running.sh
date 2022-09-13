#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-system-process.sh
# Description: a script to check process running
################################################################
# name of script
baseName=$(basename $0)
#desc: print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
# desc: print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    bash $baseName syslogd"
}

# desc: check input
check_input()
{
    if [ $# -ne 1 ];then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}
# get process status
main()
{
    check_input "$@"
    print_log "INFO" "Check $1 process"
    pid=$(pgrep "$1")
    if [[ "${pid}" != "" ]]; then
        pids=$(echo "$pid"|tr '\n' ' ')
        print_log "INFO" "Ok,process $1 is running with below pid(s): $pids"
    else
        print_log "ERROR" "Nok,process $1 is not running"
        return 1
    fi
}

main "$@"
