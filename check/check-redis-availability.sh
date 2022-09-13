#!/bin/bash

# print log functions
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

if [ $# -lt 3 ]; then
    #输入的参数少于4个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port> <password>"
    print_log "INFO" "eg:$baseName 10.0.X.X 6379 pass"
    exit 1
fi

# check client command
function check_basic_command() {
    basic_command_flag=$1

    if which $basic_command_flag >/dev/null 2>&1; then
        redis_cli=$(which $basic_command_flag)
        print_log "INFO" "redis client is ok， ${redis_cli}"
    else
        print_log "ERROR" "can not find redis client"
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
        print_log "ERROR" "cannot connect redis server:$1"
        exit 1
    fi
}

function check_methods() {

    code=""

    nowtime=$(date +%s)
    check_key="setup-tools-check-$nowtime"

    # add
    ${redis_cli} -h $redis_host -p $redis_port -a $redis_pass set $check_key $HOSTNAME-$nowtime &>/dev/null
    code=$(expr $code + $?)

    # query
    getdata=$(${redis_cli} -h $redis_host -p $redis_port -a $redis_pass get $check_key 2>/dev/null)
    [[ $getdata == $HOSTNAME-$nowtime ]]
    code=$(expr $code + $?)

    # update
    newtime=$(date +%s)
    ${redis_cli} -h $redis_host -p $redis_port -a $redis_pass set $check_key $HOSTNAME-$newtime &>/dev/null
    code=$(expr $code + $?)

    # del
    ${redis_cli} -h $redis_host -p $redis_port -a $redis_pass del $check_key &>/dev/null
    code=$(expr $code + $?)

    return $code
}

function check_redis() {

    version=$(${redis_cli} -h $redis_host -p $redis_port -a $redis_pass info 2>/dev/null | grep redis_version)
    if [ $? -ne 0 ]; then
        print_log "ERROR" "redis server $redis_host is not ok! check port or password"
        exit 1
    else
        print_log "INFO" "redis server $redis_host is ok!"
        print_log "INFO" "redis version is $(echo $version | awk -F':' '{print $2}')"
        cluster_info=$(${redis_cli} -h $redis_host -p $redis_port -a $redis_pass info 2>&1 | grep -E "(^role)" &&
            ${redis_cli} -h $redis_host -p $redis_port -a $redis_pass info 2>&1 | grep -E "(^slave[0-9])" | awk -F ',' '{print $1,$2,$3}')
        if [[ $(echo $cluster_info | sed -e 's/\r$//') == "role:slave" ]]; then
            print_log "INFO" "redis server is a slave node!"
        else
            check_methods
            if [ $? -ne 0 ]; then
                print_log "ERROR" "redis server $redis_host is not ok! can't read and write."
                exit 1
            else
                print_log "INFO" "redis node read and write is ok!"
            fi
        fi
        print_log "INFO" "about cluster status:"
        echo "$cluster_info"
        return 0
    fi

}

function main() {
    redis_host=$1
    redis_port=$2
    redis_pass=$3

    check_ip_status $redis_host

    check_basic_command redis-cli

    check_redis "$@"
}

########################
#     main program     #
########################

main "$@"
