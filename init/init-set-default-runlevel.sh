#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-set-default-runlevel.sh
# Description: a script to set default system runlevel
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    local level=$1
    case $level in
        1|runlevel1|rescue*)
            exp_level=rescue.target
            ;;
        2|runlevel2)
            exp_level=multi-user.target
            ;;
        3|runlevel3|multi-user*)
            exp_level=multi-user.target
            ;;
        4|runlevel4)
            exp_level=multi-user.target
            ;;
        5|runlevel5|graphical*)
            exp_level=graphical.target
            ;;
        *)
            print_log "ERROR" "unknown runlevel $level"
            return 1
            ;;
    esac
    if systemctl set-default "$exp_level"; then
         print_log "INFO" "default runlevel set to $exp_level ok"
         return 0
    fi
    print_log "ERROR" "default runlevel set to $exp_level failed"
    return 1
}

main "$@"
