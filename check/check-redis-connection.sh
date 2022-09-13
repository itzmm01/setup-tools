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
#redis_cli="/data/redis-5.0.7/src/redis-cli"
###需要把redis_cli 放到bin目录下
# check client command
function check_basic_command() {
    basic_command_flag="redis-cli"

    if which $basic_command_flag >/dev/null 2>&1; then
        basic_command=$(which $basic_command_flag)
        print_log "INFO" "$basic_command_flag client is ok， $basic_command"
    else
        print_log "ERROR" "can not find $basic_command_flag client"
        exit 1
    fi
}

# desc: print how to use
function check_input()
{
    if [ $# -lt 2 ]; then
        #输入的参数少于2个
        print_log "ERROR" "Missing argument"
        print_log "INFO" "usage:$baseName <ip> <port> [password]"
        print_log "INFO" "eg:$baseName 10.0.X.X 6379"
        print_log "INFO" "eg:$baseName 10.0.X.X 6379 pass"
        exit 1
    fi
}
# Check the connect status of internet
check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &> /dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
    else
        print_log "ERROR" "cannot connect redis server:$1"
        return 1
    fi
}

check_redis() {
    check_basic_command
    redis_ip=$1
    redis_port=$2
    redis_password=$3
    check_ip_status $redis_ip
    if [ -n $redis_password ];then
        redis-cli -h $1 -p $2 -a $3 --no-auth-warning info |grep redis_version >/dev/null 2>&1
    else
        redis-cli -h $1 -p $2 --no-auth-warning info |grep redis_version >/dev/null 2>&1
    fi
    
    if ! [[ $? = "0" ]]; then
        print_log "ERROR" "redis server $1 is not ok! check port or password"
        return 1
    else
        print_log "INFO" "redis server $1 is ok!"
    fi
    version=$(redis-cli -h $1 -p $2 -a $3 --no-auth-warning info |grep redis_version|awk -F':' '{print$2}')
    if [[ -z "$version" ]]; then
        print_log "ERROR" "redis version is not ok, cannot get version"
        return 1
    fi
}


function main()
{
    check_input "$@"
    check_redis "$@"
}

########################
#     main program     #
########################
main "$@"