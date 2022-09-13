#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-max-processes.sh
# Description: a script to check if limit of max processes of
# current user is ok
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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <max_processes>"
    print_log "INFO" "  max_processes: maximum processes, e.g. 65536"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 65536"
}

# desc: check if max processes limit is ok
# input: none
# output: 1/0
function check_max_open_files()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    requiredMaxProcesses="$1"

    # check if requiredMaxProcesses is valid
    # is it an integer?
    if ! is_int "$requiredMaxProcesses" >/dev/null 2>&1 ; then
        print_log "ERROR" "Input \"$requiredMaxProcesses\" is not valid. Only integer is allowed."
        print_usage
        return 1
    fi

    print_log "INFO" "Check user limit of max processes"

    maxProcesses=$(ulimit -u)
    print_log "INFO" "Current: $maxProcesses, required: $requiredMaxProcesses"
    if [ "$maxProcesses" -lt "$requiredMaxProcesses" ] ;then
        print_log "ERROR" "Nok"
        return 1
    else
        print_log "INFO" "Ok"
    fi

}


########################
#     main program     #
########################
check_max_open_files $*
