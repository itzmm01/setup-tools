#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-ulimits-corefile-off.sh
# Description: a script to check if ulimits core file size is off
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# desc: check ulimits corefile off
# input: none
# output: 1/0
function check_ulimits_corefile_off()
{
    print_log "INFO" "Check ulimits corefile entries is off."
    ulimits_core_file_size=$(ulimit -a | grep -i "core file size" | xargs | awk '{ print $6 }')
    if [[ ${ulimits_core_file_size} == "0" ]]; then
        print_log "INFO" "Check that ulimits core file is closed."
        return 0
    fi
    print_log "ERROR" "Check that ulimits core file is open, please execute init-set-ulimits-corefile repair."
    return 1
}


########################
#     main program     #
########################
check_ulimits_corefile_off
