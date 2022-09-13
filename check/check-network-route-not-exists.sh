#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-route-name.sh
# Description: a script to check if network arch on current machine
# meets requirement
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")
# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName "
    print_log "INFO" "  check_network_route: subnet"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 10.199.X.X/16"
    print_log "INFO" "  $baseName 10.199.X.X/16 172.17.X.X/16"
}


check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

check_route_format() {
    local valid_flags=0
    route_regex="(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|[1-9])(\.(1\d{2}|2[0-4]\d|25[0-5]|[1-9]\d|\d)){3}"
    subnet_prefix=$(echo "$1" | awk -F'/' '{ print $1 }')
    netmask_bit=$(echo "$1" | awk -F'/' '{ print $2 }')
    validate_prefix=$(echo "${subnet_prefix}" | grep -oP "${route_regex}")
    if [[ $1 ==  "0.0.0.0/0" ]]; then
        return 0
    fi
    if [ "${subnet_prefix}" == "${validate_prefix}" ]; then
        valid_flags=$(($valid_flags+1))
    fi
    if [[ ${netmask_bit} -lt 32 ]]; then
        valid_flags=$(($valid_flags+1))
    fi
    if [ "${valid_flags}" == 2 ]; then 
        return 0
    fi
    return 1
}

check_route_exists() {
    if [[ $1 == "0.0.0.0/0" ]]; then
        if ip route list | grep default > /dev/null 2>&1; then
            return 0
        fi
        return 1
    fi
    if ip route list | grep -w "$1" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

#input: subnet_prefix
#ouput: 0/1
check_network_route(){
    check_input "$@"
    input_subnets=("$@")
    failed_subnet_list=()
    print_log "INFO"  "check check_network_route"
    if ! which ip >/dev/null 2>&1; then
        print_log "ERROR" "Missing ip command, please install iproute package."
        exit 1
    fi 
    for subnet in "${input_subnets[@]}"; do
        if ! check_route_format "${subnet}" ; then
            print_log "ERROR" "check_network_route: ${subnet} route format failed."
            exit 1
        fi
        if check_route_exists "${subnet}"; then
           failed_subnet_list[${#failed_subnet_list[@]}]=${subnet}
        fi
    done
    if [[ ${#failed_subnet_list} -ne 0 ]]; then
        print_log "ERROR" "The potentially conflicting subnet as following: "
        echo "${failed_subnet_list[*]}"
        return 1
    fi
    print_log "INFO" "check_network_route: OK"
    return 0
}

check_network_route "$@"
