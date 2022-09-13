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
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


RET=0
check_hosts_allow() {
    local c
    c=$(grep -Ev '^#|^$' /etc/hosts.allow | wc -l)
    if [[ $c -eq 0 ]]; then
        print_log "INFO" "/etc/hosts.allow ok"
        return 0
    fi
    print_log "ERROR" "/etc/hosts.allow check failed"
    RET=1
    return 1
}

check_hosts_deny() {
    local c
    c=$(grep -Ev '^#|^$' /etc/hosts.deny | wc -l)
    if [[ $c -eq 0 ]]; then
        print_log "INFO" "/etc/hosts.deny ok"
        return 0
    fi
    print_log "ERROR" "/etc/hosts.deny check failed"
    RET=1
    return 1
}

check_hosts_allow
check_hosts_deny
exit $RET
