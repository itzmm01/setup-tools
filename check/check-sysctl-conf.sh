#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-system-conf-file.sh
# Description: check if sysctl.conf meets requirements
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
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: Choose one of the below usages."
    print_log "INFO" "Example: 1) $baseName net.ipv4.ip_local_port_range 1024 65535"
    print_log "INFO" "         2) $baseName /tmp/$USER/para-conf.ini"
    print_log "INFO" "1) $baseName <token> <value>"
    print_log "INFO" "  <token>: required, token string, e.g. net.ipv4.ip_local_port_range"
    print_log "INFO" "  <value>: required, value string, e.g. 1024 65535"
    print_log "INFO" "2) $baseName <para-file>"
    print_log "INFO" "  <para-file>: required, path to parameter file(format: token value), e.g. /tmp/$USER/para-conf.ini"
    print_log "INFO" "    example of <para-file>: "
    print_log "INFO" "    net.ipv4.ip_local_port_range 1024 65535"
    print_log "INFO" "    kernel.shmall 4294967296"
    print_log "INFO" "    net.ipv4.tcp_fin_timeout 10"
    print_log "INFO" "    net.ipv4.tcp_timestamps 1"
}


check_sysctl_conf() {
    case $# in
        0)
            print_log "ERROR" "At least 1 parameter is required."
            print_usage
            return 1
            ;;
        1)
            paraFile=$1
            # in case para file does not exist
            [ ! -f ${paraFile} ] && print_log "ERROR" "${paraFile} does not exist." && return 1
            while read line || [[ -n ${line} ]]; do
                check_kv ${line} || return 1
            done < ${paraFile}
            ;;
        *)
            check_kv "$@" || return 1
            ;;
    esac

    print_log "INFO" "Successfully checked /etc/sysctl.conf"
    return 0
}

check_kv()
{
    local k="$1"
    shift
    local v="$*"
    # in case key or value is null, return 1
    [ "$k" == "" ] && print_log "ERROR" "key is null for value $v." && return 1
    [ "$v" == "" ] && print_log "ERROR" "value is null for key $k." && return 1
    # k = d or k=d
    # delete and append
    current_v=$(sysctl -n ${k} | sed -e 's/[[:space:]][[:space:]]*/ /g')
    "print_log" "INFO" "System conf key: ${k}, current value: ${current_v}, required value: ${v}"
    [ "${current_v}" != "${v}" ] && print_log "ERROR" "Nok." && return 1
    print_log "INFO" "Ok." && return 0
}

########################
#     main program     #
########################
check_sysctl_conf "$@"
