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

function is_int()
{
    str=$1

    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        return 1
    fi

    print_log "INFO" "Check if $str is a valid positive integer."
    if [[ $str =~ ^[+-]?[0-9]+$  ]]; then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "ERROR" "Nok."
        return 1
    fi
}




# name of script
baseName=$(basename "$0")

check_input() {
    if [ $# -lt 2 ]; then
        print_log "ERROR" "at least two argument is required."
        print_log "INFO" "Usage:$baseName <ip> <ports,>"
        exit 1
    fi
}

check_tcp_conn() {
    local ipaddr=$1
    shift
    local ports="$*"
    local failed_ports
    for port in $(echo "$ports" | tr ',' ' '); do
        if ! is_int "$port"; then
            print_log "ERROR" "Invalid input ${port}, please input as number"
            return 1
        fi
        if ! timeout 3 bash -c "echo > /dev/tcp/$ipaddr/$port 2>/dev/null" 2>/dev/null; then
            print_log "ERROR" "cannot connect to $ipaddr:$port"
            failed_ports="$failed_ports $port"
        fi
    done
    if [[ -n "$failed_ports" ]]; then
        print_log "ERROR" "failed ports: $failed_ports"
        return 1
    fi
    print_log "INFO" "tcp connection ok"
    return 0
}

check_input "$@"
check_tcp_conn "$@"
