#!/bin/bash

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
baseName=`basename $0`

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path> <mod>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName /tmp 777"

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


function check_path_mod()
{
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two parameter is required."
        print_usage
        return 1
    fi
    path_flag=$1
    mod_flag=$2
    if [ -z "$path_flag" ]; then
        print_log "ERROR" "Input is empty."
        return 1
    fi

    if ! is_int $mod_flag ; then
        print_log "ERROR" "MOD MUST INT"
    fi

    stat_mod=$(stat $path_flag |sed -n '4p'|awk -F '[(/]+' '{print $2}'|cut -c 2-4)
    if [ $stat_mod -eq $mod_flag ]; then
        print_log "INFO" "match Ok"
        return 0
    else
        print_log "ERROR" "NOT match Nok"
        return 1
    fi
}


check_path_mod $*
