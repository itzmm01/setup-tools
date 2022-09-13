#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-sudoer.sh
# Description: a script to set sudoers
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

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <action> <user> [config_entry]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName add testuser ALL=/bin/chown,/bin/chmod "
        exit 1
    fi
}
# name of script
baseName=$(basename $0)

# input: action, user, config_entry
# output: 1/0
set_sudo() {
    check_input "$@"
    local action="$1"
    local user="$2"
    shift 2
    local entry="$*"
    if [[ $action = del ]]; then
        /bin/rm /etc/sudoers.d/udc-init-$user
        return
    fi
    cat >/etc/sudoers.d/udc-init-$user<<EOF
$user $entry
EOF
    chmod 440 /etc/sudoers.d/udc-init-$user
}


########################
#     main program     #
########################
set_sudo "$@"
