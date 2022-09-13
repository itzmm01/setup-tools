#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-current-runlevel.sh
# Description: a script to check current system runlevel
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    local level=$1
    local crt_level
    if [[ -x /sbin/runlevel ]]; then
        crt_level=$(/sbin/runlevel | awk '{print $2}')
    else
        crt_level=$(who -r | awk '{print $2}')
    fi
    case $level in
        1|runlevel1|rescue*)
            exp_level=1
            ;;
        2|runlevel2)
            exp_level=2
            ;;
        3|runlevel3|multi-user*)
            exp_level=3
            ;;
        4|runlevel4)
            exp_level=4
            ;;
        5|runlevel5|graphical*)
            exp_level=5
            ;;
        *)
            print_log "ERROR" "unknown runlevel $level"
            return 1
            ;;
    esac
    if [[ "$crt_level" = "$exp_level" ]]; then
         print_log "INFO" "current runlevel is $crt_level, check ok"
         return 0
    fi
    print_log "ERROR" "current runlevel is $crt_level, not $exp_level, check failed"
    return 1
}

main "$@"
