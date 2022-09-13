#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-remove-default-nproc-nofile-limits-conf.sh
# Description: a script to remove default nproc/nofile limits conf
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    /bin/rm -f /etc/security/limits.d/*nproc.conf
    /bin/rm -f /etc/security/limits.d/*nofile.conf
    local num
    num=$(ls /etc/security/limits.d/{*nproc.conf,*nofile.conf} 2>/dev/null | wc -l)
    if [[ $num -eq 0 ]]; then
        print_log "INFO" "remove default nproc/nofile conf ok"
        return 0
    fi
    print_log "ERROR" "remove default nproc/nofile conf failed"
    return 1
}

main
