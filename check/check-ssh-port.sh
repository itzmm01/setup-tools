#!/bin/bash
##################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ssh-root-login.sh
# Description: a script to check if setting "Port "
# is configured in file /etc/ssh/sshd_config to permit root login
##################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <ssh_port>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 22"
        exit 1
    fi
}
# desc: check if "Port " is set in file /etc/ssh/sshd_config
# input: none
# output: 1/0
function check_ssh_root_login()
{
    check_input "$@"
    check_prot=$1
    print_log "INFO" "Check if \"Port $check_prot\" is set in file /etc/ssh/sshd_config"
    port_set=$(cat /etc/ssh/sshd_config | grep -E "^Port.*")
    if [ $check_prot -eq 22 ];then
        if [ -n "$port_set" ] ;then
            isSet=$(echo "$port_set"| grep "$check_prot")
        else
            isSet=$(cat /etc/ssh/sshd_config | grep -E "^#Port.*" | grep "$check_prot\s*$")
        fi
    else
        isSet=$(echo "$port_set"| grep -E "^Port\s+$check_prot\s*$")
    fi
    if [ "$isSet" == "" ];then
        print_log "ERROR" "Nok."
        return 1
    else
        print_log "INFO" "Ok."
        return 0
    fi
}


########################
#     main program     #
########################
check_ssh_root_login "$@"
