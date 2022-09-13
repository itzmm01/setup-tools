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

function check_input() {
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Extactly one argument is required."
        print_log "INFO" "Usage:$baseName <ports>"
        print_log "INFO" "e.g. $baseName 8080"
        exit 1
    fi
}

function check_port_active() {
    port=$1

    if ss -ln "( sport = :$port )" | grep -oq ":$port" >/dev/null 2>&1; then
        print_log "INFO" "$port is active"
        return 0
    else
        print_log "ERROR" "$port is not active!"
        exit 1
    fi
}

check_input "$@"

check_port_active "$@"
