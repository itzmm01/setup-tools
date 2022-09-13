#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-selinux.sh
# Description: a script to check if selinux is disabled
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

# desc: check if selinux is disabled
# input: none
# output: 1/0
function check_selinux()
{

    print_log "INFO" "Check selinux status."
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    if [ "$os_version" == "uos" ] ;then
        print_log "INFO" "Ok. Selinux status is disabled."
        return 0
    fi

    isSet=$(grep SELINUX=disabled /etc/selinux/config)
    isDisabled=$(getenforce)

    if [ "$isDisabled" != "Disabled" -a "$isDisabled" != "SELINUX=disabled" ];then
        print_log "ERROR" "Nok. Selinux status is not disabled."
        return 1
    else
        print_log "INFO" "Ok. Selinux status is disabled."
        return 0
    fi
}


########################
#     main program     #
########################
check_selinux
