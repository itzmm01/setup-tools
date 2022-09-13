#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-link-delected.sh
# Description: a script to check link delected  is yes on current machine
################################################################
# name of script
baseName=$(basename $0)
#desc:print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <link_delected>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName eth0"

}

#desc: check input
check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found"
       exit 1
    fi
}

#desc: print link delected Is the expectation met
#input: link delected
#ouput: 0/1
check_link_delected(){
    check_command ethtool
    check_input $@
    input_link_delected=$(ethtool $1|grep "Link detected"|awk '{print $3}')
    if [[ "$input_link_delected" == "yes" ]] ;then 
         print_log "INFO" "ok."
    else
         print_log "ERROR" "Nok,Current: $local_link_delected"
         return 1
        
    fi
}

check_link_delected $@
