#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-cgroup-kmem-off.sh
# Description: a script to check if cgroup.memory=nokmem parameter is ok
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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
function check_cgroup_kmem_off()
{
    print_log "INFO" "Check grub file cgroup config status"
    if grep -q "cgroup.memory=nokmem" /proc/cmdline; then
        print_log "INFO" "Ok cgroup kmem is off"
        return 0
    else
        if grep -q "cgroup.memory=nokmem" /etc/default/grub; then
            print_log "ERROR" "Nok, group kmem is not off. In case conf has changed, please reboot to take effect."
            return 1
        fi
        print_log "ERROR" "Nok, cgroup kmem is not off, please add cgroup.memory=nokmem parameter to the /etc/default/grub and reboot."
        return 1
    fi
}

########################
#     main program     #
########################
check_cgroup_kmem_off
