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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")

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


function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Extactly one argument is required."
        print_log "INFO" "Usage:$baseName <ports>"
        print_log "INFO" "e.g. $baseName 8080"
        print_log "INFO" "e.g. $baseName 8080 8081 80"
        exit 1
    fi
}

function check_port_available()
{
    port=$1
    if ! is_int "$port" >/dev/null 2>&1; then
        print_log "ERROR" "Invalid input ${port}, please input as number"
        return 1
    fi

    if which lsof >/dev/null 2>&1; then
        if lsof -i:"${port}" -sTCP:LISTEN >/dev/null; then
            print_log "ERROR" "${port} is already listening"
            return 1
        fi
    else
        if ss -ln "( sport = :$port )" | grep -wq ":$port" >/dev/null 2>&1; then
            print_log "ERROR" "${port} is already listening"
            return 1
        fi
    fi
    print_log "INFO" "${port} is available"
    return 0
}

function main()
{
    check_input "$@"
    allOk=0
    for port in "$@"; do
        if ! check_port_available "${port}"; then
            allOk=1
         
        fi
    done
    return ${allOk}
}


main "$@"
