#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-global-limits.sh
# Description: a script to set global limit
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

_limits() {
    local domain="$1"
    local ltype="$2"
    local item="$3"
    local value="$4"
    local limitsconf=/etc/security/limits.conf
    if [[ $ltype = '-' ]]; then
        sed -i "/^$domain[[:space:]]\+soft[[:space:]]\+$item[[:space:]]\+/d" $limitsconf
        sed -i "/^$domain[[:space:]]\+hard[[:space:]]\+$item[[:space:]]\+/d" $limitsconf
        sed -i "/^$domain[[:space:]]\+-[[:space:]]\+$item[[:space:]]\+/d" $limitsconf
    else
        sed -i "/^$domain[[:space:]]\+$ltype[[:space:]]\+$item[[:space:]]\+/d" $limitsconf
        sed -i "/^$domain[[:space:]]\+-[[:space:]]\+$item[[:space:]]\+/d" $limitsconf
    fi
    printf "%-6s %-5s %-7s %s\n" $domain $ltype $item $value >>$limitsconf
}
# desc: set nproc
# input: user max_proc_no
# output: 1/0
set_global_limit() {
    sed -i -e '$a\' /etc/security/limits.conf
    set -o noglob
    _limits @users soft nofile  100001
    _limits @users hard nofile  100002
    _limits @root  soft nofile  100001
    _limits @root  hard nofile  100002
    _limits *      -    nofile  655360
    _limits *      -    nproc   655360
    _limits *      -    memlock unlimited
    _limits *      -    core    unlimited
    retval=$?
    set +o noglob
    if [ $retval -eq 0 ]; then
        print_log "INFO" "Set global limits: ok."
        return 0
    fi
    print_log "INFO" "Set global limits: failed."
    return 1
}


########################
#     main program     #
########################
set_global_limit
