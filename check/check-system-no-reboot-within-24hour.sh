#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-system-no-reboot-within-24hour.sh
# Description: a script to check system no reboot within 24 hours
################################################################
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo -e "$currentTime    [$log_level]    $log_msg"
}
INFO="\033[32mINFO\033[0m"
ERROR="\033[31mERROR\033[0m"
#desc: system reboot in 24hour
system_reboot()
{
    system_reboot_status=$(uptime|awk '{print $4}')
    if [[ $system_reboot_status =~ 'day' ]];then
        print_log "$INFO" "Ok. system no reboot within 24 hours"
        return 0
    fi
    print_log "$ERROR" "Nok. system reboot within 24 hours"
    return 1
}
########################
#     main program     #
########################
system_reboot 
