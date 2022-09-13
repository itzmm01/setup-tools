#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-route-reached.sh
# Description: a script to check if route reached
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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <route_ip> "
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 192.168.X.X"

}
#desc: check input
check_input() {
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

# desc: check if ip not in network segment
# input: ip  network-segment
# output: 1/0
function route_reached(){
    check_input "$@"
    ping -c 4 $1
    if [ $? -ne 0 ]; then
        print_log "ERROR" "route don't reached"
        return 1
    else
        print_log "INFO" "route reached"
    fi

}
route_reached "$@"
