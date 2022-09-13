#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ip-not-in-network-segment.sh
# Description: a script to check if ip not in network segment
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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <ip> <network segment>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 192.168.X.X 192.168.X.X/24"

}

# desc: check if ip not in network segment
# input: ip  network-segment
# output: 1/0
function check_ip_not_in_network_segment(){
    which "ipcalc" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_log "ERROR" "ipcalc cmd must require"
        return 1
    fi

    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two parameter is required."
        print_usage
        return 1
    fi

    ip_flag=$1
    network_segment_flag=$2
    /usr/bin/ipcalc -c $ip_flag && /usr/bin/ipcalc -c $network_segment_flag
    if [ $? -ne 0 ]; then
        print_log "ERROR" "parameter failed and check is legality"
        print_usage
        return 1
    fi

    min_ip=`/usr/bin/ipcalc -n $network_segment_flag|awk -F '=' '{print $2}'`
    max_ip=`/usr/bin/ipcalc -b $network_segment_flag|awk -F '=' '{print $2}'`
    MIN_IP=`echo $min_ip|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
    MAX_IP=`echo $max_ip|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
    IPvalue=`echo $ip_flag|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
    if [ "$IPvalue" -ge "$MIN_IP" ] && [ "$IPvalue" -le "$MAX_IP" ];then
        print_log "ERROR" "ip in network segment Nok."
        return 1
    else
        print_log "INFO" "ip not in network segment Ok."
        return 0
    fi
}


########################
#     main program     #
########################
check_ip_not_in_network_segment $*
