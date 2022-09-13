#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-dns-search-options-off.sh
# Description: a script to check if dns is disable search entry
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

# desc: check dns search
# input: none
# output: 1/0
function check_dns_search_options_off()
{
    print_log "INFO" "Check /etc/resolv.conf search entry."
    if grep -q -E "^search" /etc/resolv.conf; then
        print_log "ERROR" "search entry was detected at /etc/resolv.conf."
        return 1
    fi
    print_log "INFO" "Not found search entry in /etc/resolv.conf."
    return 0
}


########################
#     main program     #
########################
check_dns_search_options_off
