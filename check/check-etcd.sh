#!/bin/bash

# print log functions
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

if [ $# -lt 2 ]; then
    #输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port> [username] [password]"
    print_log "INFO" "eg:$baseName 10.0.X.X 2379 [username] [password]"
    exit 1
fi

# check client command
function check_basic_command() {
    basic_command_flag=$1

    if which $basic_command_flag >/dev/null 2>&1; then
        etcdctl=$(which $basic_command_flag)
        print_log "INFO" "etcd client is ok， $etcdctl"
    else
        print_log "ERROR" "can not find etcd client"
        exit 1
    fi
}

# Check the connect status of internet
function check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &>/dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
        return 0
    else
        print_log "ERROR" "cannot connect etcd server:$1"
        exit 1
    fi
}

# 查看是否更改了默认的存储容量
options=$(ps -ef | grep [e]tcd | awk '{for(i=8; i<=NF; i++) print $i}')
set_total=$(
    for option in $options; do
        echo $option | grep -P 'quota-backend-bytes=\d+' | awk -F"=" '{print $2}'
    done
)

if [ -s $set_total ]; then
    # 默认容量2g
    total=2097152
else
    total=$set_total
fi

function check_etcd() {

    endpoints=$1:$2
    etcd_user=$3
    etcd_pass=$4

    export ETCDCTL_API=3

    nowtime=$(date +%s)
    check_key="setup-tools-check-$nowtime"

    code=""

    #add
    $etcdctl --endpoints=$endpoints --user=$etcd_user:$etcd_pass put $check_key $HOSTNAME-$nowtime &>/dev/null
    code=$(expr $code + $?)

    #update
    newtime=$(date +%s)
    $etcdctl --endpoints=$endpoints --user=$etcd_user:$etcd_pass put $check_key $HOSTNAME-$newtime &>/dev/null
    code=$(expr $code + $?)

    #query
    getdata=$($etcdctl --endpoints=$endpoints --user=$etcd_user:$etcd_pass get --print-value-only $check_key 2>/dev/null)
    [[ $getdata == $HOSTNAME-$newtime ]]
    code=$(expr $code + $?)

    #del
    $etcdctl --endpoints=$endpoints --user=$etcd_user:$etcd_pass del $check_key &>/dev/null
    code=$(expr $code + $?)

    if [[ $code -ne 0 ]]; then
        print_log "ERROR" "etcd node $1 is not ok! check server status or password"
        exit 1
    else
        print_log "INFO" "etcd node read and write is ok!"
        # 计算存储空间用量
        used=$($etcdctl --user=$etcd_user:$etcd_pass endpoint status | awk '{gsub(",",""); if ($5 ~ /kB/) print $4;if ($5 ~ /MB/) print $4*1024; if ($5 ~ /GB/) print $4*1024*1024}')
        # 计算百分比，结果乘以100显示更加直观(读作百分之)
        count=$(awk 'BEGIN{printf "%.6f\n",'${used}'/'${total}'*'100'}')

        print_log "INFO" "etcd quota backend bytes total is: $total"
        print_log "INFO" "etcd quota backend bytes used: $count%"
        cluster_info=$($etcdctl --endpoints=$endpoints --user=$etcd_user:$etcd_pass member list -w table)
        print_log "INFO" "about cluster status:"
        echo "$cluster_info"
        return 0
    fi
}

function main() {
    check_basic_command etcdctl

    check_ip_status $1

    check_etcd "$@"
}

########################
#     main program     #
########################

main "$@"
