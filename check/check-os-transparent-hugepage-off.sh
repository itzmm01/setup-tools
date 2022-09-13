#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check_os_transparent_hugepage_off.sh
# Description: a script to check if transparent_hugepage=never parameter is ok
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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
function check_transparent_hugepage_off()
{
    local transparent_hugepage_flags=0
    print_log "INFO" "Check transparent_hugepage status"
    if grep -q '\[never\]' /sys/kernel/mm/transparent_hugepage/enabled; then
        transparent_hugepage_flags=$((${transparent_hugepage_flags}+1))
    fi
    if grep -q '\[never\]' /sys/kernel/mm/transparent_hugepage/defrag; then
        transparent_hugepage_flags=$((${transparent_hugepage_flags}+1))
    fi
    if [[ "${transparent_hugepage_flags}" == 2 ]]; then
        print_log "INFO" "Ok, transparent hugepage is off."
        return 0
    fi
    print_log "ERROR" "Nok, transparent hugepage is not off."
    return 1
}

########################
#     main program     #
########################
check_transparent_hugepage_off
