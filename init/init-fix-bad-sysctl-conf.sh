#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
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


# output: 1/0
main() {
    if sysctl -p >/dev/null 2>&1; then
        print_log "INFO" "sysctl.conf ok"
        return 0
    fi
    print_log "INFO" "try to auto fix sysctl.conf ..."
    if ! cat /proc/sys/net/netfilter/nf_conntrack_max >/dev/null 2>&1; then
        sed -i 's/^net.nf_conntrack_max/#net.nf_conntrack_max/g' /etc/sysctl.conf
        sed -i 's/^net.netfilter.nf_conntrack_max/#net.netfilter.nf_conntrack_max/g' /etc/sysctl.conf
    fi
    for item in $(sysctl -p |& grep 'sysctl: cannot stat'|awk '{print $4}'|sed 's#^/proc/sys/##;s#:$##'|tr '/' '.'); do
        sed -i "/^$item = .*$/d" /etc/sysctl.conf
        sed -i "/^$item=.*$/d" /etc/sysctl.conf
    done
    if sysctl -p >/dev/null 2>&1; then
        print_log "INFO" "sysctl.conf ok"
        return 0
    fi
    print_log "ERROR" "auto fix sysctl.conf failed"
    return 1
}


########################
#     main program     #
########################
main
