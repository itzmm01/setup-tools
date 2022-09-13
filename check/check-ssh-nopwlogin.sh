#!/bin/bash

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
baseName=`basename $0`

if [ $# -lt 2 ]; then
    #输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port>"
    print_log "INFO" "eg:$baseName 10.0.X.X 22"
    exit 1
fi

check_ssh() {
    ip=$1
    ssh_prot=$2
    ssh $ip -p$ssh_prot -o PreferredAuthentications=publickey -o StrictHostKeyChecking=no "date" > /dev/null 2>&1
    if [ $? == "0" ]; then
        print_log "INFO" "$ip is ok ,can login without password!"
        return 0
    fi
    print_log "ERROR" "$ip is not ok,can not login without password!"
    return 1
}

##### main #####
check_ssh $@
