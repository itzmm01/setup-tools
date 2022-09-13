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
    print_log "INFO" "usage:$baseName <ip> <domain>"
    print_log "INFO" "usage:"
    print_log "INFO" "eg:$baseName 10.0.X.X XX.XX.com"
    exit 1
fi

check_hosts() {
    local ip="$1"
    local domain="$2"
    #获取hosts文件内容
    num=$(cat /etc/hosts|grep -v '::1'|grep -v "^#"|grep -E "$domain\s+"|grep $ip |wc -l)
    if [[ $num -eq '1' ]]; then
        print_log "INFO" "hosts config is ok"
        return 0
    fi
    print_log "ERROR" "hosts config is not ok"
    return 1
}

######main######
check_hosts $1 $2
