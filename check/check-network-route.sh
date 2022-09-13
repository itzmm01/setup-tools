#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-route-name.sh
# Description: a script to check if network arch on current machine
# meets requirement
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
    print_log "INFO" "Usage: $baseName <gateway-ip>"
    print_log "INFO" "  check_network_route:  gateway-ip"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  ipaddress"
}


check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

#desc: print cpu arch Is the expectation met
#input: network_name
#ouput: 0/1
check_network_route(){
    check_input $@
    input=$1
    print_log  "INFO"  "check check_network_route"
    error=0
    [[ `echo ${input} | grep -oP "(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|[1-9])(\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)){3}"` == ${input} ]] &&  error=1
    [[ `echo ${input} | grep -oP "(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|[1-9])(\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)){3}/[0-9]{1,2}"` == ${input} ]] && error=1
    [[ ${input} ==  "0.0.0.0" ]]  &&  error=1
    if [ ${error} == 0 ]; then 
        print_log "ERROR" "check_network_route:IP format failed"
        print_usage
        exit 1
    fi
	if  which ip >/dev/null 2>&1; then
		 if  [ ${input} == "0.0.0.0" ] ; then 
		    ip route list | grep -w "default"  > /dev/null 2>&1  &&  { print_log  "INFO"  "check_network_route: OK" ; return 0; }
            print_log  "ERROR"  "check_network_route: failed" && return 1  
         fi
         if ip route list | grep -w "${input}"  > /dev/null 2>&1; then
            print_log  "INFO"  "check_network_route: OK" &&  return 0
         fi
    fi
	     print_log "ERROR"  "check_network_route：failed" && return 1
}

check_network_route $@
