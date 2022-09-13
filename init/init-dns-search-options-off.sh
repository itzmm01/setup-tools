#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-dns-search-options-off.sh
# Description: a script to check if /etc/resolv.conf search entries is disabled
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

# desc: init set dns search
# input: none
# output: 1/0
function init_dns_search_options_off()
{
    print_log "INFO" "disable search entry in /etc/resolv.conf succeeded."
    sed -i 's/^search.*/# &/' /etc/resolv.conf && return 0
    print_log "ERROR" "disable search entry in /etc/resolv.conf failed."
    return 1
}

########################
#     main program     #
########################
init_dns_search_options_off
