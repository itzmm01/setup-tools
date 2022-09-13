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

if [ $# -lt 1 ]; then
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <url> [status code]"
    print_log "INFO" "usage: if you doesn't give a status code, default code is 200"
    print_log "INFO" "eg:$baseName https://XXX.com"
    print_log "INFO" "eg:$baseName https://XXX.com:8443/index.html 301"
    exit 1
fi

check_url() {

    url=$1
    if [ ! -s $2 ]; then
        code=$2
    else
        code=200
    fi

    getcode=$(curl -s -m 5 -o /dev/null -w "%{http_code}\\n" "$url")
    [[ $getcode -eq $code ]]

    if [[ $? -ne 0 ]]; then
        print_log "ERROR" "get error http code!"
        print_log "ERROR" "return error code: $getcode"
        exit 1
    else
        print_log "INFO" "$url is ok!"
        time_total=$(curl -o /dev/null -s -w "%{time_total}\n" "$url")
        print_log "INFO" "connect time: $time_total"
        print_log "INFO" "http code: $code"
        return 0
    fi

}

########################
#     main program     #
########################

check_url "$@"
