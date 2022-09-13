#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-max-processes.sh
# Description: a script to set max processes
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

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName [user] <max-openfiles>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 65536"
        print_log "INFO" "  $baseName root 65536"
        exit 1
    fi
}

#----------------------------------------------------------
# desc: check if a given string is valid positive integer
# parameters: string
# return: 1/0
#----------------------------------------------------------
function is_int()
{
    str=$1
    if [[ ! $str =~ ^[+-]?[0-9]+$  ]]; then
        print_log "ERROR" "Nok."
        exit 1
    fi
}

# desc: set nproc
# input: user max_proc_no
# output: 1/0
set_nproc() {
    check_input "$@"
    if [[ $# -eq 1 ]];then
        local nproc="$1"
        is_int "$nproc"
        cat >/etc/security/limits.d/all-user-nproc.conf <<EOF
*   hard nproc $nproc
*   soft nproc $nproc
EOF
        if [[ $? -eq 0 ]];then
            print_log "INFO" "OK"
            return 0
        fi
    else
        local user="$1"
        local nproc="$2"
        is_int "$nproc"
        cat >/etc/security/limits.d/${user}-nproc.conf <<EOF
$user   hard nproc $nproc
$user   soft nproc $nproc
EOF
        if [[ $? -eq 0 ]];then
            print_log "INFO" "OK"
            return 0
        fi
    fi
    print_log "ERROR" "Nok";return 1
}

########################
#     main program     #
########################
set_nproc "$@"
