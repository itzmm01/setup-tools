#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-ssh-ciphers.sh
# Description: a script to check if sshd ciphers option
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName ciphers"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 3des-cbc;"
        print_log "INFO" "  $baseName 3des-cbc aes128-cbc aes256-cbc;"
        exit 1
    fi
}

# desc: check_ssh_ciphers
# input: none
# output: 1/0
function check_ssh_ciphers()
{
    check_input "$@"
    input_ciphers=("$@")
    not_exist_ciphers=()
    not_support_ciphers=()
    print_log "INFO" "Check ssh ciphers."
    for cip in "${input_ciphers[@]}"; do
        if ! ssh -Q cipher | grep -q "^${cip}$"; then
            not_support_ciphers[${#not_support_ciphers[@]}]=$cip
        fi
        if ! sshd -T | grep ciphers | grep -q -w "${cip}"; then
            not_exist_ciphers[${#not_exist_ciphers[@]}]=$cip
        fi
    done
    if [[ ${#not_support_ciphers[@]} -ne 0 ]]; then
        print_log "ERROR" "The cipher don't support in ssh -Q cipher as following: "
        echo "${not_support_ciphers[*]}"
        return 1
    fi
    if [[ ${#not_exist_ciphers[@]} -ne 0 ]]; then
        print_log "ERROR" "The cipher don't exist in the /etc/ssh/sshd_config as following: "
        echo "${not_exist_ciphers[@]}"
        return 1
    else
        print_log "INFO" "Found ssh cipher in the sshd."
        return 0
    fi
}

########################
#     main program     #
########################
check_ssh_ciphers "$@"
