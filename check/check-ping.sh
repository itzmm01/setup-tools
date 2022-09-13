#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-vip-ping.sh
# Description: a script check vip ping 
# meets requirement
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
function print_usage(){
    print_log "INFO" "Usage: $baseName <ip_addr> <rtt> <loss>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 192.168.X.X~192.168.X.X 20 30"
}
#desc: check print
function check_input()
{
    if [[ $# -ne 3 ]] && [[ $# -ne 4 ]]; then
        print_log "ERROR" "Exactly three or four argument is required."
        print_usage
        exit 1
    fi
}
# desc: check ping check
# input: ip_addr rtt loss
# output: 1/0
function check_ping(){
    check_input "$@"
    local targetIP=$1             
    local -i delay=$2             
    local -i lossRate=$3          
    local -i pingCount="3"
    if [ $# -eq 4 ]; then
      pingCount=$4
    fi
    print_log "INFO" "check ping vip:$1 delay less than $2ms lossRate less than $3, ping count is $pingCount"
    local errorOut=""
    local resultOutput=""
    local iLossRate=""
    local iDelay=""
    isAllOk=0
    targetIP=(${targetIP//,/ })
    for ip in ${targetIP[*]}; do
      if [[ $ip =~ '~' ]]; then
         a=$(echo $ip | cut -d \~ -f 1|awk -F"[.]" '{print $1}')
         b=$(echo $ip | cut -d \~ -f 1|awk -F"[.]" '{print $2}')
         c=$(echo $ip | cut -d \~ -f 1|awk -F"[.]" '{print $3}')
         d1=$(echo $ip | cut -d \~ -f 1|awk -F"[.]" '{print $4}')
         d2=$(echo $ip | cut -d \~ -f 2|awk -F"[.]" '{print $4}')
         for i in `seq $d1 $d2`; do 
            print_log "INFO" "$a.$b.$c.$i"
            ip=$a.$b.$c.$i
            #交换机或者当前主机上没有对端的arp信息，第一个ping包高概率出现loss的现象，因此先ping一个包，不统计结果
            ping -c 1 ${ip} >> /dev/null 2>&1
            resultOutput=$(ping -c ${pingCount} ${ip})
            iLossRate=$(echo ${resultOutput}|grep -Eo '[0-9]+% packet loss'|grep -Eo '[0-9]+')
            iDelay=$(echo ${resultOutput}|awk -F '/' '{print $5}')
            iDelay1=$(echo $iDelay|grep -o '[0-9]\+'|awk 'NR==1')
            if [[ $iLossRate -gt $3 ]]||[[ $iDelay1 -gt $2 ]]; then
            print_log "ERROR" "Nok,ping -c ${pingCount} ${ip} loss:$iLossRate% avg:$iDelay ms"
            isAllOk=1
            else 
            print_log "INFO" "Ok,ping -c ${pingCount} ${ip} loss:$iLossRate% avg:$iDelay ms"
            fi
        done
     else 
        print_log "INFO" "$ip"
        ping -c 1 ${ip} >> /dev/null 2>&1
        resultOutput=$(ping -c ${pingCount} ${ip})
        iLossRate=$(echo ${resultOutput}|grep -Eo '[0-9]+% packet loss'|grep -Eo '[0-9]+')
        iDelay=$(echo ${resultOutput}|awk -F '/' '{print $5}')
        iDelay1=$(echo $iDelay|grep -o '[0-9]\+'|awk 'NR==1')
        if [[ $iLossRate -gt $3 ]]||[[ $iDelay1 -gt $2 ]]; then
        print_log "ERROR" "Nok,ping -c ${pingCount} ${ip} loss:$iLossRate% avg:$iDelay ms"
        isAllOk=1
        else 
        print_log "INFO" "Ok,ping -c ${pingCount} ${ip} loss:$iLossRate% avg:$iDelay ms"
        fi
      fi    
    done
    return ${isAllOk}
}
check_ping "$@"
