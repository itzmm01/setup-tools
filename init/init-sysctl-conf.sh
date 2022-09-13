#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-sysCtl-conf.sh
# Description: a script to manage sysctl.conf
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
print_usage() {
    print_log "INFO" "Usage: Choose one of the below usages."
    print_log "INFO" "Example: 1) $baseName net.ipv4.ip_local_port_range 1024 65535"
    print_log "INFO" "         2) $baseName /tmp/para-conf.ini"
    print_log "INFO" "1) $baseName <token> <value>"
    print_log "INFO" "  <token>: required, token string, e.g. net.ipv4.ip_local_port_range"
    print_log "INFO" "  <value>: required, value string, e.g. 1024 65535"
    print_log "INFO" "2) $baseName <para-file>"
    print_log "INFO" "  <para-file>: required, path to parameter file(format: token value), e.g. /tmp/para-conf.ini"
    print_log "INFO" "    example of <para-file>: "
    print_log "INFO" "    net.ipv4.ip_local_port_range 1024 65535"
    print_log "INFO" "    kernel.shmall 4294967296"
    print_log "INFO" "    net.ipv4.tcp_fin_timeout 10"
    print_log "INFO" "    net.ipv4.tcp_timestamps 1"
}


set_sysctl_conf() {
    case $# in
        0)
            print_log "ERROR" "At least 1 parameter is required."
            print_usage
            return 1
            ;;
        1)
            paraFile=$1
            # in case para file does not exist
            if [[ ${paraFile::4} = "http" ]]; then
                curl -sL "$paraFile" -o /tmp/.init_sys_conf_params.txt
                if [[ -s /tmp/.init_sys_conf_params.txt ]]; then
                    paraFile=/tmp/.init_sys_conf_params.txt
                else
                    print_log "ERROR" "${paraFile} does not exist."
                    return 1
                fi
            fi
            if ! [[ -f ${paraFile} ]]; then
                print_log "ERROR" "${paraFile} does not exist."
                return 1
            fi
            while read line || [[ -n ${line} ]]; do
                set_kv ${line} || return 1
            done < ${paraFile}
            ;;
        *)
            set_kv "$@" || return 1
            ;;
    esac

    print_log "INFO" "Successfully set /etc/sysctl.conf"
    return 0
}

set_kv() {
    local k="$1"
    shift
    local v="$*"
    # in case key or value is null, return 1
    [ "$k" == "" ] && print_log "ERROR" "key is null for value $v." && return 1
    [ "$v" == "" ] && print_log "ERROR" "value is null for key $k." && return 1
    # k = d or k=d
    # delete and append
    sed -i "/^$k =/d" /etc/sysctl.conf
    sed -i "/^$k=/d" /etc/sysctl.conf
    [[ -n "$(tail -c1 /etc/sysctl.conf )" ]] && echo >>/etc/sysctl.conf
    echo "$k = $v" >>/etc/sysctl.conf
}

########################
#     main program     #
########################
set_sysctl_conf "$@"
