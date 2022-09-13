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

if [ $# -lt 4 ]; then
    # number of arguments less than 4.
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port> <username> <password>"
    print_log "INFO" "eg:$baseName 10.0.X.X 8161 admin password"
    exit 1
fi

# Check the connect status of internet
check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &>/dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
        return 0
    fi
    return 1
}

check_activemq() {
    health=$(curl -s --connect-timeout 5 -u $3:$4 "http://$1:$2/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/CurrentStatus" 2>/dev/null | grep -o \"value\"\:\"Good\")
    echo $health | grep -oq "Good"
    if [ $? -eq 0 ]; then
        print_log "INFO" "activemq server $1 is ok!"
        return 0
    else
        print_log "ERROR" "activemq server $1 is not ok! check server status or password"
        exit 1
    fi
}

check_ip_status $1
if [ $? -ne 0 ]; then
    print_log "ERROR" "cannot connect activemq server:$1"
    exit 1
fi

check_activemq $1 $2 $3 $4
