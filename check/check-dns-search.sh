#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-dns-search.sh
# Description: a script to check if firewalld is disabled
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

# desc: check hosts repeat
# input: none
# output: 1/0
function check_dns_search()
{
    
    print_log "INFO" "Check /etc/resolv.conf search entry." 
    search_result=$(grep -E "^search" /etc/resolv.conf)
    if [ "$search_result" == "" ];then
        print_log "INFO" "Check /etc/resolv.conf search entry passed."
        return 0
    else
        print_log "ERROR" "search entry was detected at /etc/resolv.conf, which may cause the pod parsing svc to fail, please delete it."
        return 1
    fi
}


########################
#     main program     #
########################
check_dns_search
