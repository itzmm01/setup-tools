#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check_network_internet.sh
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





#desc: print cpu arch Is the expectation met
#ouput: 0/1
check_network_internet(){
     url="114.114.114.114"
     if [ -n "${1}" ]; then
        url=${1}
     fi
     if  which  ping  >/dev/null 2>&1; then
         print_log "INFO" "check check_network_internet"
         #交换机或者当前主机上没有对端的arp信息，第一个ping包高概率出现loss的现象，因此先ping一个包，不统计结果
         ping -c 1 ${url} >> /dev/null 2>&1
         if  ping -c 3  ${url} >/dev/null 2>&1; then
           print_log "INFO" "check_network_internet:OK" && return  0
         fi
           print_log "ERROR" "check_network_internet: failed"  && return 1
	 fi
	     print_log "ERROR" "check_network_internet: not ping tools" &&  return 1
}

check_network_internet $@
