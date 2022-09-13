#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-host-ipv6-enable.sh
# Description: a script to check if host ipv6 protocol is enable
################################################################
#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
check_ipv6_enable() {
    print_log "INFO" "Check IPv6 protocol status"
    if [[ ! -d "/proc/sys/net/ipv6" ]]; then
        print_log "ERROR" "The current IPv6 protocol disabled, please add ipv6.disable=0 to the /etc/default/grub and reboot os"
        return 1
    fi
    ipv6_status=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
    if [[ "${ipv6_status}" -ne "0" ]]; then
        print_log "ERROR" "The current IPv6 protocol disabled, please add net.ipv6.conf.all.disable_ipv6=0 to /etc/sysctl.conf and sysctl -p"
        return 1
    fi
    print_log "INFO" "The current IPv6 protocol enabled"
    return 0
}

########################
#     main program     #
########################
check_ipv6_enable
