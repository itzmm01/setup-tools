#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
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


check_ssh_sshd_ver() {
    local ssh_ver
    local sshd_ver
    ssh_ver="$(ssh -V |& awk '{print $1}'|sed 's/,//g'|tr '[:upper:]' '[:lower:]')"
    sshd_ver="$(/usr/sbin/sshd --help |& grep -i openssh | awk '{print $1}'|sed 's/,//g'|tr '[:upper:]' '[:lower:]')"
    if ! [[ $ssh_ver = "$sshd_ver" ]]; then
        print_log "ERROR" "ssh/sshd err($ssh_ver != $sshd_ver)"
        return 1
    fi
        print_log "INFO" "check OK, ssh_ver = sshd_ver"
    return 0
}

check_ssh_sshd_ver
