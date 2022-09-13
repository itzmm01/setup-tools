#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-docker-version.sh
# Description: a script to check if current docker server version
# is the same as the input version
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
baseName=$(basename "$0")

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Desc: Check if current docker version is greater than or equal to required input version"
    print_log "INFO" "Usage: $baseName <docker-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 1.10.0"

}

# desc: check docker version
# input: docker-version
# output: 1/0
function check_currentVersion()
{
    requredVersion=$1
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    requredVersion=$1
    # docker-version
    print_log "INFO" "Check docker version"
    if command -v docker >/dev/null 2>&1; then
        currentVersion=$(docker --version 2>&1|awk -F '[ ,]+' '{print $3}')
        print_log "INFO" "Current: ${currentVersion}, required: ${requredVersion}"
        # compare input and docker version
        retcode=$(awk -v  ver1="${requredVersion}" -v ver2="${currentVersion}"  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        [ "${retcode}" != "0" ] && print_log "INFO" "Nok" && return 1
        print_log "INFO" "Ok"
    else
        print_log "ERROR" "Docker command is not found in system env"
        return 1
    fi

}


check_currentVersion "$@"
