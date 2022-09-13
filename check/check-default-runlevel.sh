#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-default-runlevel.sh
# Description: a script to check default system runlevel
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    local level=$1
    local def_level
    def_level=$(systemctl get-default)
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
            exp_level=multi-user.targcheck-redis-connection.shet
            ;;
        5|runlevel5|graphical*)
            exp_level=graphical.target
            ;;
        *)
            print_log "ERROR" "unknown runlevel $level"
            return 1
            ;;
    esac
    if [[ "$def_level" = "$exp_level" ]]; then
         print_log "INFO" "default runlevel is $def_level, check ok"
         return 0
    fi
    print_log "ERROR" "default runlevel is $def_level, not $exp_level, check failed"
    return 1
}

main "$@"
