#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-remount-rw-cgroup-fs.sh
# Description: a script to remount cgroup fs to rw mode
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    if ! [ -d /sys/fs/cgroup ]; then
        print_log "INFO" "no cgroup fs found, do nothing."
        return 0
    fi
    if mount | grep '/sys/fs/cgroup ' | grep -q 'rw,'; then
        print_log "INFO" "cgroup fs already mounted rw."
        return 0
    fi
    if mount -o remount,rw /sys/fs/cgroup; then
        print_log "INFO" "remount cgroup fs rw ok."
        return 0
    fi
    print_log "ERROR" "remount cgroup fs rw failed."
    return 1
}

main
