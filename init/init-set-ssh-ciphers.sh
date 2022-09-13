#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-ssh-ciphers.sh
# Description: a script add new ciphers to /etc/ssh/sshd_config
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

# desc: init_set_ssh_ciphers
# input: ciphers
# output: 1/0
function init_set_ssh_ciphers()
{
    check_input "$@"
    local input_ciphers=("$@")
    local add_ciphers_list=()
    local not_support_ciphers=()
    local add_ciphers
    print_log "INFO" "Set ssh ciphers."
    for cip in "${input_ciphers[@]}"; do
        if ! ssh -Q cipher | grep -q "^${cip}$"; then
            not_support_ciphers[${#not_support_ciphers[@]}]=$cip
        fi
        if ! sshd -T | grep ciphers | grep -q -w "${cip}"; then
            add_ciphers_list[${#add_ciphers_list[@]}]=$cip
        fi
    done
    if [[ ${#not_support_ciphers[@]} -ne 0 ]]; then
        print_log "ERROR" "The cipher don't support in ssh -Q cipher as following: "
        echo "${not_support_ciphers[*]}"
        return 1
    fi
    [[ $(tail -c1 /etc/ssh/sshd_config) ]] && echo "" >> /etc/ssh/sshd_config
    if grep -q -E ^Ciphers /etc/ssh/sshd_config; then
        add_ciphers=$(echo "${add_ciphers_list[*]}" | tr ' ' ',')
        sed -i "s/^Ciphers.*/&,""$add_ciphers""/" /etc/ssh/sshd_config
    else
        if [[ ${#add_ciphers_list[@]} -ne 0 ]]; then
            add_ciphers=$(echo "${input_ciphers[*]}" | tr ' ' ',')
            sed -i "$ a Ciphers ""$add_ciphers""" /etc/ssh/sshd_config
        fi
    fi
    print_log "INFO" "Set ssh ciphers success."
    return 0
}

########################
#     main program     #
########################
init_set_ssh_ciphers "$@"
