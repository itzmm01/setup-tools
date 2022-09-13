#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-ssh-permit-root-login.sh
# Description: a script to config ssh setting to permit ssh 
# login via user root
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

# desc: set PermitRootLogin to yes in file /etc/ssh/sshd_config
# input: none
# output: none
function set_PermitRootLogin()
{
    sshd_config_file="/etc/ssh/sshd_config"
    set_content="PermitRootLogin yes"
    #print_log "INFO" "Set PermitRootLogin in file $sshd_config_file" 
    #print_log "INFO" "Check if PermitRootLogin is set: cat $sshd_config_file | grep -e '^PermitRootLogin.*'"
    isSet=$(cat "$sshd_config_file" | grep -e '^PermitRootLogin .*')
    if [ "$isSet" == ""  ]; then
        #print_log "INFO" "PermitRootLogin is not set. Will add 'PermitRootLogin yes' to file $sshd_config_file"
        [[ -n "$(tail -c1 $sshd_config_file )" ]] && echo >>$sshd_config_file
        echo "$set_content" >> "$sshd_config_file"
    else
        #print_log "INFO" "PermitRootLogin is set. Will replace exist setting '$isSet' with 'PermitRootLogin yes' to file $sshd_config_file"
        sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config_file"
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
set_PermitRootLogin

