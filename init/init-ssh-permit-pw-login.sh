#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-ssh-permit-pw-login.sh
# Description: a script to config ssh setting to permit ssh 
# login via username/password
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
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename $0)

# desc: set PasswordAuthentication to yes in file /etc/ssh/sshd_config
# input: none
# output: none
function set_PasswordAuthentication()
{
    sshd_config_file="/etc/ssh/sshd_config"
    set_content="PasswordAuthentication yes"
    #print_log "INFO" "Set PasswordAuthentication in file $sshd_config_file" 
    #print_log "INFO" "Check if PasswordAuthentication is set: cat $sshd_config_file | grep -e '^PasswordAuthentication.*'"
    isSet=$(cat "$sshd_config_file" | grep -e '^PasswordAuthentication .*')
    if [ "$isSet" == ""  ]; then
        #print_log "INFO" "PasswordAuthentication is not set. Will add 'PasswordAuthentication yes' to file $sshd_config_file"
        [[ -n "$(tail -c1 $sshd_config_file )" ]] && echo >>$sshd_config_file
        echo "$set_content" >> "$sshd_config_file"
    else
        #print_log "INFO" "PasswordAuthentication is set. Will replace exist setting '$isSet' with 'PasswordAuthentication yes' to file $sshd_config_file"
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config_file"
    fi
    
    if [ $? -eq 0 ]; then
        print_log "INFO" "Set '$set_content' in file '$sshd_config_file': ok" 
    else
        print_log "ERROR" "Set '$set_content' in file '$sshd_config_file': failed" 
    fi
}


########################
#     main program     #
########################
set_PasswordAuthentication

