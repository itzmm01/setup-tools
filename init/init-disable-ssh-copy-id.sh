#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-disable-ssh-copy-id.sh
# Description: a script to disable ssh-copy-id for user
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName [user]"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName"
    print_log "INFO" "  $baseName  liner"
}

# desc: check input params
function check_input()
{
    if [ $# -gt 1 ]; then
        print_usage
        exit 1
    fi
}


# desc: disable ssh-copy-id for user, root as default
# input: path
# output: 1/0
function main()
{
    check_input "$@"
    local user="root"
    if [[ -n $1 ]]; then
      if ! grep -E -q "^$1:" /etc/passwd; then
        print_log "ERROR" "user $1 not found."
        print_log "ERROR" "Nok, disable ssh-copy-id for user $1: fail"
        return 1
      fi
      user=$1
    fi
    user_home_path=$(grep -E "^$user:" /etc/passwd | awk -F ":" '{print $(NF-1)}')
    if [[ -f $user_home_path/.ssh/authorized_keys ]]; then
      /bin/mv "$user_home_path"/.ssh/authorized_keys "$user_home_path"/.ssh/authorized_keys.tmp
      if [[ $? -ne 0 ]];then
        print_log "ERROR" "Nok, disable ssh-copy-id for user $user: fail"
        return 1
      fi
    fi
    print_log "INFO" "Ok, disable ssh-copy-id for user $user."
    return 0
}
########################
#     main program     #
########################
main "$@"
