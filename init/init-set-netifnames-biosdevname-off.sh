#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-set-netifnames-biosdevname-off.sh
# Description: script to set net.ifnames and biosdevname in grub
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
set_grub() {
    if grep '^GRUB_CMDLINE_LINUX=' /etc/default/grub | grep -q "net.ifnames=0"; then
        print_log "INFO" "net.ifnames=0 already set"
        return 0
    fi

    sed -i -e 's|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 |g' /etc/default/grub
    if grub2-mkconfig -o /boot/grub2/grub.cfg; then
        print_log "INFO" "update grub config success."
        return 0
    fi
    print_log "ERROR" "update grub config failed"
    return 1
}

set_grub
