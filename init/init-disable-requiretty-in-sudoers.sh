#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-disable-requiretty-in-sudoers.sh
# Description: a script to disable requiretty in /etc/sudoers
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    if sed -i 's/^Defaults    requiretty/Defaults    !requiretty/' /etc/sudoers; then
        print_log "INFO" "disable requiretty in sudoers ok"
        return 0
    fi
    print_log "ERROR" "disable requiretty in sudoers failed"
    return 1
}

main
