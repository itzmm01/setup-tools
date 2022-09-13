#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-dns-server.sh
# Description: a script to set dns server
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <dns_server_address>"
    print_log "INFO" "  init-set-dns: dns_server_address"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  114.114.114.114"
}

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

# desc: check if a given string is valid ipv4 address
# parameters: string
# return: 1/0
is_ipv4() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# desc: set dns server
# input: dns_server_address
# output: 1/0
set_dns_server() {
    check_input "$@"
    local dns_server_address="$1"
    if is_ipv4 "$dns_server_address";then
        print_log "INFO" "set dns server"
        for server in $(cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}')
        do
            if [ $server == "$dns_server_address" ]; then
                print_log "INFO" "dns server is exist"
                print_log "INFO" "dns server set ok"
                return 0
            fi
        done
    cat >> /etc/resolv.conf << EOF

nameserver $1
EOF
        if [ $? -eq 0 ]; then
            print_log "INFO" "dns server set ok"
            return 0
        fi
        print_log "ERROR" "dns server set failed"
        return 1
    fi
    print_log "ERROR" "input dns_server_address $dns_server_address is not correct ip address"
    print_usage
    exit 1     
}

########################
#     main program     #
########################
set_dns_server "$@"