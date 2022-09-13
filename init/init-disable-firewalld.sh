#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-disable-firewalld.sh
# Description: a script to disable and stop firewalld service
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

# desc: disable firewalld
# input: none
# output: none
disable_firewalld() {
    if ! [ -f /usr/lib/systemd/system/firewalld.service ]; then
        print_log "INFO" "firewalld not installed"
        return 0
    fi
    if systemctl disable firewalld && systemctl stop firewalld; then
        print_log "INFO" "Disable and stop firewalld: ok"
        return 0
    fi
    print_log "ERROR" "Disable and stop firewalld: failed"
    return 1
}


########################
#     main program     #
########################
disable_firewalld
