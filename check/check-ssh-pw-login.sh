#!/bin/bash
##################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ssh-pw-login.sh
# Description: a script to check if setting
# "PasswordAuthentication yes" is configured in file
# /etc/ssh/sshd_config to permit login via user & password
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

# desc: check if "PasswordAuthentication yes" is set in file /etc/ssh/sshd_config
# input: none
# output: 1/0
function check_ssh_pw_login()
{
    print_log "INFO" "Check if \"PasswordAuthentication yes\" is set in file /etc/ssh/sshd_config"
    isSet=`cat /etc/ssh/sshd_config | grep -E "^PasswordAuthentication.*" | grep "yes"`
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
check_ssh_pw_login
