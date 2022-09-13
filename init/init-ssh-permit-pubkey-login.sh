#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
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

# desc: set PubkeyAuthentication to yes in file /etc/ssh/sshd_config
# input: none
# output: none
function set_PubkeyAuthentication()
{
    sshd_config_file="/etc/ssh/sshd_config"
    set_content="PubkeyAuthentication yes"
    #print_log "INFO" "Set PubkeyAuthentication in file $sshd_config_file" 
    #print_log "INFO" "Check if PubkeyAuthentication is set: cat $sshd_config_file | grep -e '^PubkeyAuthentication.*'"
    isSet=$(cat "$sshd_config_file" | grep -e '^PubkeyAuthentication .*')
    if [ "$isSet" == ""  ]; then
        #print_log "INFO" "PubkeyAuthentication is not set. Will add 'PubkeyAuthentication yes' to file $sshd_config_file"
        [[ -n "$(tail -c1 /etc/ssh/sshd_config )" ]] && echo >>/etc/ssh/sshd_config 
        echo "$set_content" >> "$sshd_config_file"
    else
        #print_log "INFO" "PubkeyAuthentication is set. Will replace exist setting '$isSet' with 'PubkeyAuthentication yes' to file $sshd_config_file"
        sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/g' "$sshd_config_file"
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
set_PubkeyAuthentication
