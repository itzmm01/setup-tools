#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-etc-hosts-duplicate-entries.sh
# Description: a script to check if /etc/hosts entries is duplicate
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

# desc: check hosts duplicate entries
# input: none
# output: 1/0
function check_etc_hosts_duplicate_entries()
{
    print_log "INFO" "Check /etc/hosts duplicate entries."
    local ip_list host_list duplicate_entries localhost_entries
    ip_list=$(grep -v '^$' /etc/hosts | awk '{ print $1 }' | sort | uniq -c | awk '{ if($1>1) print $2 }' | xargs)
    host_list=$(grep -v '^$' /etc/hosts | awk '{ print $2 }' | sort | uniq -c | awk '{ if($1>1) print $2 }' | xargs)
    duplicate_entries="$ip_list $host_list"
    localhost_entries=$(grep -E "127.0.0.1\s+localhost" /etc/hosts)
    check_env=0
    if [[ "${#duplicate_entries}" -gt 1 ]];then
        print_log "ERROR" "Duplicate entries are found in /etc/hosts as follows:"
        echo "$duplicate_entries"
        check_env=1
    fi
    if [[ -z "$localhost_entries" ]];then
        print_log "ERROR" "Not found 127.0.0.1 localhost entry in /etc/hosts."
        check_env=1
    fi
    if [[ "$check_env" -eq 0 ]]; then
        print_log "INFO" "Not found in /etc/hosts duplicate entries."
        return 0
    fi
    return 1
}

########################
#     main program     #
########################
check_etc_hosts_duplicate_entries
