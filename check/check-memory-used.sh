#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-memory-used.sh
# Description: a script to check if memory size on current
# machine meets requirement
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
    print_log "INFO" "Usage: $baseName <memory utilization rate>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 0.8"
}

function main()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
    res=`free -m|grep -w 'Mem'|awk '{if ($6/$2 > '$1') print $6/$2}'`
    if [ "$res" == "" ]; then
      print_log "INFO" "memory utilization < $1"
    else
      print_log "ERROR" "memory utilization: $res > $1"
      exit 1
    fi
}

########################
#     main program     #
########################
main "$@"
