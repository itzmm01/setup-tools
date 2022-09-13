#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-ulimits-corefile-off.sh
# Description: a script to set ulimits core file size to 0.
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

# desc: init set ulimits corefile off
# input: none
# output: 1/0
function init_set_ulimits_corefile_off()
{
    print_log "INFO" "Set ulimits core file size to 0."
    ulimits_core_file_size=$(ulimit -a | grep -i "core file size" | xargs | awk '{ print $6 }')
    if [[ ${ulimits_core_file_size} == "0" ]]; then
        print_log "INFO" "ulimits core file is closed. skip this step."
        return 0
    else
        ulimit -c 0
        [[ -n "$(tail -c1 /etc/profile)" ]] && echo "" >> /etc/profile
        if ! grep -q "ulimit.*-S.*-c.*0" /etc/profile; then
            echo "ulimit -S -c 0" >> /etc/profile
        fi
        print_log "INFO" "Set ulimits core file size to 0 is ok."
        return 0
    fi
    
}

########################
#     main program     #
########################
init_set_ulimits_corefile_off
