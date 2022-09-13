#!/bin/bash
##################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ssh-root-login.sh
# Description: a script to check if setting "PermitRootLogin yes"
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

# desc: check if "PermitRootLogin yes" is set in file /etc/ssh/sshd_config
# input: none
# output: 1/0
function check_ssh_root_login()
{
    print_log "INFO" "Check if \"PermitRootLogin yes\" is set in file /etc/ssh/sshd_config"
    isSet=`cat /etc/ssh/sshd_config | grep -E "^PermitRootLogin.*" | grep "yes"`
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
check_ssh_root_login
