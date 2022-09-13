#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-root.sh
# Description: a script to monitor collection mac
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
        print_log "INFO" "Usage: $baseName <netcard_name>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName eth0"
        exit 1
    fi
}

# desc: monitor collection mac
function monitor_collection_mac()
{
    check_input $@
	print_log "INFO" "monitor collection mac"
	netcard_name=$1
    collection_mac=$(cat /sys/class/net/"$netcard_name"/address)
    collection_ip=$(ifconfig "$netcard_name"|grep -E "inet\s.*"|awk '{print $2}')
	if [ -n "$collection_mac" ];then
		print_log "INFO" "Ok collection ${collection_ip} mac ${collection_mac}"
        echo "${collection_ip} ${collection_mac}"
        return 0
	else
		print_log "ERROR" "Nok collection ${collection_ip} mac faild"
		return 1
	fi
}

########################
#     main program     #
########################
monitor_collection_mac "$@"