#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-disable-firewalld.sh
# Description: a script to disable selinux
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

# desc: disable selinux
# input: none
# output: none
function disable_selinux()
{
    selinux_conf_file="/etc/selinux/config"
    set_content="SELINUX=disabled"
    # print_log "INFO" "Set selinux in file $selinux_conf_file" 
    #print_log "INFO" "Check if SELINUX=disabled is set: cat $selinux_conf_file | grep -e '^SELINUX=.*'"
    isSet=$(cat "$selinux_conf_file" | grep -e '^SELINUX=.*')
    if [ "$isSet" == ""  ]; then
        #print_log "INFO" "SELINUX is not set. Will add 'SELINUX=disabled' to file $selinux_conf_file"
        [[ -n "$(tail -c1 $selinux_conf_file )" ]] && echo >>$selinux_conf_file
        echo "$set_content" >> "$selinux_conf_file"
    else
        #print_log "INFO" "SELINUX is set. Will replace exist setting '$isSet' with 'SELINUX=disabled' to file $selinux_conf_file"
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' "$selinux_conf_file"

    fi
    
    if [ $? -eq 0 ]; then
        print_log "INFO" "Set '$set_content' in file '$selinux_conf_file': ok." 
    else
        print_log "ERROR" "Set '$set_content' in file '$selinux_conf_file': failed."
        return 1
    fi
    
    setenforce 0 >/dev/null 2>&1
    print_log "INFO" "Run command 'setenforce 0': ok." 
    return 0
}


########################
#     main program     #
########################
disable_selinux

