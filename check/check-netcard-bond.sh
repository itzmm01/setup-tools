#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-network-name.sh
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
    print_log "INFO" "Usage: $baseName <netcard_name>  <bond_type>"
    print_log "INFO" "  check_netcard_bond:  netcard_name  bond-name"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  eth1  bond1 "
}


check_input()
{
    if [ $# != 2 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly two argument is required."
        print_usage
        exit 1
    fi
}

#desc: print cpu arch Is the expectation met
#input: bond_name
#input: eth_name
#ouput: 0/1
check_netcard_bond(){
    check_input $@
	print_log "INFO" "check check_netcard_bond"
    bond=$2
	eth=$1
	[[ `lsmod | grep -w "bonding"` ]] ||  { print_log "ERROR" "check_netcard_bond: bonding model is not install" ; return 1; }
	if [ -f /proc/net/bonding/${bond} ]; then
        if  cat /proc/net/bonding/${bond}  | grep -w "Slave Interface" | grep -w "${eth}" > /dev/null 2>&1 ; then
            print_log "INFO" "check_netcard_bond:OK" &&  return 0
        fi  
            print_log "INFO" "check_netcard_bond:failed" && return 1
	fi
		print_log "ERROR" "check_netcard_bond: not find ${bond}" &&  return 1	
}

check_netcard_bond $@
