#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-os-bootmode.sh
# Description: a script to check if on os boot mode on current machine.
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName <boot_mode>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName BIOS"

}

check_os_boot_mode() {
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
    print_log "INFO" "Check os boot mode."
    boot_mode_flags=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    if [ -d /sys/firmware/efi ]; then
        curr_boot_mode="UEFI"
    else
        curr_boot_mode="BIOS"
    fi
    print_log "INFO" "current: ${curr_boot_mode} required: ${boot_mode_flags}"
    if [ "${boot_mode_flags}" == "${curr_boot_mode}" ]; then
        print_log "INFO" "Check boot mode ok."
        return 0
    fi
    print_log "ERROR" "Check boot mode Nok."
    return 1
}

########################
#     main program     #
########################
check_os_boot_mode "$@"
