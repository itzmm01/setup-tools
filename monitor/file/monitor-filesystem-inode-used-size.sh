#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-filesystem-inode-used-size.sh
# Description: a script to monitor filesystem inode used size
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
# desc: print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName /data"
}

#desc: check input
check_input()
{
    if [ $# -ne 1 ];then
        print_log "ERROR" "Exactly one arguments is required."
        print_usage
        exit 1
    fi
}

# get filesystem inode used size
main()
{
    check_input "$@"
    used=""
    count=$(df -h | grep "$1$"|wc -l)
    if [[ $count -eq 0 ]]; then
        print_log "ERROR" "filesystem:$1 not exist."
        exit 1
    else
        used=$(df -i | grep "$1$" | awk '{print $3}')
        echo "$used"
    fi

}
main "$@"
