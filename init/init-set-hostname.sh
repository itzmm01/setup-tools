#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-hostname.sh
# Description: a script to set hostname
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <host_name>"
    print_log "INFO" "  init-set-hostname:  host_name"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  node01"
}

check_input()
{
    if [ $# != 1 ]; then
    #check argument
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

function main()
{
    check_input "$@"
    local hostname="$1"
    local hostname_conf_file="/etc/sysconfig/network"
    #check hostname
    if [ -z "${hostname}" ]; then
        print_log ERROR "hostname=${hostname} is null."
        return 1
    fi
    #hostnamectl setting hostname 
    which hostnamectl > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        which hostname > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_log ERROR "Command hostname doesn't exist."
            return 1
        fi
        hostname "${hostname}"
        if [ $? -ne 0 ]; then
            print_log ERROR "Modify hostname failed for ${hostname}."
            return 1
        fi
        echo "${hostname}" > "/etc/hostname"
        if [ $? -ne 0 ]; then
            print_log ERROR "Modify /etc/hostname failed."
            return 1
        fi
        print_log "INFO" "set hostname ${hostname}：ok"
        return 0
    fi
    #permanently set the hostname
    grep "^[[:space:]]*HOSTNAME[[:space:]]*=" "${hostname_conf_file}" > /dev/null
    if [ $? -ne 0 ]; then
        [[ -n "$(tail -c1 ${hostname_conf_file} )" ]] && echo >>${hostname_conf_file}
        echo "HOSTNAME=${hostname}" >> "${hostname_conf_file}"
    else
        sed -i "s/^[[:space:]]*HOSTNAME[[:space:]]*=.*/HOSTNAME=${hostname}/g" "${hostname_conf_file}"
        if [ $? -ne 0 ]; then
            print_log ERROR "Modify ${hostname_conf_file} failed for HOSTNAME=${hostname}."
            return 1
        fi
    fi            
    #temporary setting hostname
    hostname "${hostname}"
    if [ $? -ne 0 ]; then
        print_log ERROR "run command hostname ${hostname} failed."
        return 1
    fi
    print_log "INFO" "set hostname ${hostname}：ok"
    return 0
}

########################
#     main program     #
########################
main "$@"