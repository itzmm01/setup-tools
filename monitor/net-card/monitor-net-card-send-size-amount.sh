#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-net-card-send-size-amount.sh
# Description: a script to monitor network card send size amount
################################################################
# name of script
baseName=$(basename $0)
#desc: print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc: print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName vda "
}
#desc: check input
function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}


#desc: getnetwork card send size amount
net_card_send_size_amount()
{
    check_command ethtool
    check_input "$@"
    count=$(ethtool $1|grep "Link detected"|wc -l)
    if [[ $count -eq 0 ]] ;then
       print_log "ERROR" "network card:$1 not be exist."
       exit 1
    fi   
    sx=$(cat /proc/net/dev | grep $1 | sed 's/:/ /g' | awk '{print $10}')
    echo "$sx"
}
net_card_send_size_amount "$@"

