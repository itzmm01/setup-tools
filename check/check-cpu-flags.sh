#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-cpu-flags.sh
# Description: a script to check if cpu flags on current machine
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
baseName=$(basename $0)


# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName <cpu_flags>"
    print_log "INFO" "  cpu_flags: e.g. avx2"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName avx2"

}

# desc: check if cpu flag is ok
# input: cpu_flag, operator
# output: 1/0
check_cpu_flag() {
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    local cpu_flag=$1
    print_log "INFO" "Check if cpu flags is ok."
    # check if cpu_flag is valid
    # get  cpu flags on current machine
    cpuflag_ok=$(grep $cpu_flag /proc/cpuinfo)
    if [[ -z "$cpuflag_ok" ]]; then
        print_log "ERROR" "cpu not support $cpu_flag" "Nok."
        return 1
    fi
    print_log "$cpu_flag is ok"
    return 0
}


########################
#     main program     #
check_cpu_flag $*
