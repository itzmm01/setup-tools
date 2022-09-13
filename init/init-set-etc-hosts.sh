#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-etc-hosts.sh
# Description: a script to add host entries in /etc/hosts
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName filename [is_overwrite]"
        print_log "INFO" "Usage: $baseName entries [is_overwrite]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName hosts_file false"
        print_log "INFO" "  $baseName 127.0.0.1 localhost true"
        print_log "INFO" "hosts_file content reference:"
        print_log "INFO" "127.0.0.1 localhost"
        print_log "INFO" "127.0.0.2 localhost2"
        exit 1
    fi
}

# name of script
baseName=$(basename "$0")

# desc: init set hosts
# input: filename or host_entries
# output: 1/0
function init_set_etc_hosts()
{
    print_log "INFO" "add entries to /etc/hosts."
    check_input "$@"
    local entries_file=$1
    [[ -n "$(tail -c1 /etc/hosts)" ]] && echo "" >> /etc/hosts
    # input file
    if [[ -f "$entries_file" ]]; then
        is_overwrite=${2:-"false"}
        rm -f /tmp/hosts.{tmp,fail}
        while read -r entries || [[ -n ${entries} ]]; do
            ip=$(echo "$entries" | awk '{print $1}')
            fqdn=$(echo "$entries" | awk '{print $2}')
            if check_entries_compliance "$ip" "$fqdn"; then
                echo "$entries" >> /tmp/hosts.tmp
            else
                echo "$entries" >> /tmp/hosts.fail
            fi
        done < "$entries_file"
        if [[ -f /tmp/hosts.tmp ]]; then
            while read -r entries || [[ -n ${entries} ]]; do
                ip_field=$(echo "$entries" | awk '{print $1}')
                ip_exists_etc_hosts=$(grep -e "$ip_field\s.*" /etc/hosts)
                if [ -n "$ip_exists_etc_hosts" ]; then
                    if [[ "$is_overwrite" == true ]]; then
                        sed -i "s/$ip_exists_etc_hosts/$entries/" /etc/hosts
                    else
                        print_log "ERROR" "The ip entries: $ip_field already exists in /etc/hosts."
                        echo "$entries" >> /tmp/hosts.fail
                    fi
                else
                    echo "$entries" >> /etc/hosts
                fi
            done < "/tmp/hosts.tmp"
            rm -f /tmp/hosts.tmp
        else
            print_log "WARING" "No entries were added to /etc/hosts."
        fi
        if [[ -f /tmp/hosts.fail ]]; then
            print_log "ERROR" "Failed to add some entries to the /etc/hosts, as following:"
            rm -f /tmp/hosts.fail
            return 1
        fi
    # input entries
    else
        ip=$1
        fqdn=$2
        is_overwrite=${3:-"false"}
        if [[ -z $ip || -z $fqdn ]]; then
            print_log "ERROR" "You need to enter two parameters."
            return 1
        fi
        if ! check_entries_compliance "$ip" "$fqdn"; then
            print_log "ERROR" "Failed to add $ip $fqdn to the /etc/hosts."
            return 1
        fi
        ip_exists_etc_hosts=$(grep -e "$ip\s.*" /etc/hosts)
        if [ -n "$ip_exists_etc_hosts" ]; then
            if [[ "$is_overwrite" == true ]]; then
                sed -i "s/$ip_exists_etc_hosts/$ip $fqdn/" /etc/hosts
            else
                #print_log "ERROR" "Duplicate entries record to the /etc/hosts."
                print_log "ERROR" "The ip entries: ""$ip"" already exists in /etc/hosts."
                return 1
            fi
        else
            echo "$ip $fqdn" | sed 's/[ \t]*$//g' >> /etc/hosts
        fi
    fi
    print_log "INFO" "Entries added to /etc/hosts success."
    return 0
}

function check_entries_compliance() {
    local ip=$1
    local fqdn=$2
    local ip_regex="^([0-9]{1,3}[.]){3}[0-9]{1,3}$"
    local fqdn_regex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
    local check_pass=0
    if echo "$ip" | grep -q -P "$ip_regex"; then
        check_pass=$((check_pass+1))
    fi
    if echo "$fqdn" | grep -q -P "$fqdn_regex"; then
        check_pass=$((check_pass+1))
    fi
    if [[ $check_pass -eq 2 ]]; then
        return 0
    fi
    return 1
}

########################
#     main program     #
########################
init_set_etc_hosts "$@"
