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

# check client command
function check_basic_command() {
    basic_command_flag="mysql"

    if which $basic_command_flag >/dev/null 2>&1; then
        basic_command=$(which $basic_command_flag)
        print_log "INFO" "$basic_command_flag client is ok， $basic_command"
    else
        print_log "ERROR" "can not find $basic_command_flag client"
        exit 1
    fi
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 4 ]; then
    #输入的参数少于4个
        print_log "ERROR" "Missing argument"
        print_log "INFO" "usage:$baseName <ip> <port> <username> <password>"
        print_log "INFO" "eg:$baseName 10.0.X.X 3306 root password"
        exit 1
    fi
}


# Check the connect status of internet
check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &> /dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
        return 0
    else
        print_log "ERROR" "cannot connect mysql server:$1"
        return 1
    fi
    
}

check_mysql() {
    check_basic_command
    mysql_ip=$1
    mysql_port=$2
    mysql_user=$3
    mysql_password=$4
    check_ip_status $mysql_ip
    mysql -h"$mysql_ip" -P"$mysql_port" -u"$mysql_user" -p"$mysql_password"    -s -e "select version();" >/dev/null 2>&1
    if ! [[ $? -eq 0 ]]; then
        print_log "ERROR" "mysql server $1 is not ok! check ip, username, port, password!"
        return 1
    else
        print_log "INFO" "mysql server $1 is ok!"
    fi
    version=$(mysql -h $1 -u$3 -p$4   -P$2 -s -e "select version();" |grep -v version|awk -F'-' '{print $1}')
    if [[ -z "$version" ]]; then
        print_log "ERROR" "mysql version is not ok, cannot get version"
        return 1
    fi
}

function main()
{
    check_input "$@"
    check_mysql "$@"
}

########################
#     main program     #
########################
main "$@"
