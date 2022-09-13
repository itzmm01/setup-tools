#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-set-time-sync.sh
# Description: a script to set time sync
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename $0)
#desc:check command exist
function check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}
# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <ntp server> [is_set_cront] [cront_time_interval]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 202.112.10.36"
        print_log "INFO" "  $baseName cn.pool.ntp.org"
        print_log "INFO" "  $baseName cn.pool.ntp.org false"
        print_log "INFO" "  $baseName cn.pool.ntp.org true 20"
        exit 1
    fi
}
#check int
function is_int()
{
    str=$1
    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        print_usage
        exit 1
    fi
    if [[ $str =~ ^[+-]?[0-9]+$  ]]; then
        return 0
    else
        print_log "ERROR" "Nok. Input Parameter must number type."
        print_usage
        exit 1
    fi
}
# input: none
# output: 1/0
function set_time_sync()
{
    check_input $@
    check_command ntpdate    
    #set local var
    local ntp_server="$1"
    local is_set_cront="$2"
    local cront_time_interval=$3
    cront_user="root"
    [[ "$is_set_cront" != "false" ]] && is_set_cront="true"
    [[ -n "$cront_time_interval" ]] || cront_time_interval=20
    [[ "$is_set_cront" = "false" ]] || cront_time_interval=20
    #check cront user
    if ! id "$cront_user"  >/dev/null 2>&1;then
        print_log  "ERROR"  "Nok, cront user $cront_user not exist."
        return 1        
    fi
    #check cront time interval
    is_int $cront_time_interval
    if ! (($cront_time_interval >= 1 && $cront_time_interval <= 59));then
        print_log  "ERROR"  "Nok, the cronttime interval is between 1~59."
        return 1
    fi
    #test ntp server time sync
    /usr/sbin/ntpdate -u $ntp_server >/dev/null 2>&1
    if [ $? -ne 0 ];then
        print_log  "ERROR"  "Nok, ntp server $ntp_server can't time sync."
        return 1
    fi
    #check time sync crontab
    if "$is_set_cront";then
        if [ ! -f /var/spool/cron/$cront_user ];then
            echo >>/var/spool/cron/$cront_user
        fi
        if ! grep "$ntp_server" /var/spool/cron/$cront_user|awk '{print $1}'|grep -qw $cront_time_interval;then
            [[ -n "$(tail -c1 /var/spool/cron/$cront_user)" ]] && echo >>/var/spool/cron/$cront_user
            echo "*/$cront_time_interval * * * * /usr/sbin/ntpdate -u $ntp_server > /dev/null &" >> /var/spool/cron/$cront_user
            if [ $? -ne 0 ];then
                print_log  "ERROR"  "Nok, set time sync：failed."
                return 1
            fi                 
        fi
    fi
    print_log "INFO" "Ok, set time sync: success"
    return 0
}
########################
#     main program     #
########################
set_time_sync $@