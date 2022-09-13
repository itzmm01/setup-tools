#!/bin/bash
function print_log()
{
    log_level=$1
    log_msg=$2
    current_time=`echo $(date +%F%n%T)`
    echo "$current_time    [$log_level]    $log_msg"
}

function check_mac() {
    ip1=$1
    vip=$2
    mac1=$(arp -n | grep -w "${ip1}" | awk '{print $3}')
    mac2=$(arp -n | grep -w "${vip}" | awk '{print $3}')
    if [ "${mac1}" == "${mac2}" ]; then
        return 0
    else
        print_log "ERROR" "mac address is inconsistent."
        return 1
    fi
}

check_mac "$@"