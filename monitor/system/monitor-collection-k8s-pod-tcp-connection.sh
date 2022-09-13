#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: monitor-collection-k8s-pod-tcp-connection.sh
# Description: a script to collection pod tcp connection
################################################################
#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo -e "$currentTime    [$log_level]    $log_msg"
}
#desc: desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
# name of script
baseName=$(basename "$0")
INFO="\033[32mINFO\033[0m"
ERROR="\033[31mERROR\033[0m"
# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <pod_name> [namespace]"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName wemeet-controller"
    print_log "INFO" "  $baseName tke-gateway tke"

}
#
function main()
{
    check_command kubectl
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
    pod_name_para="$1"
    namespace_pare="$2"
    if [ -n "$namespace_pare" ];then
        get_pod_command="kubectl -n $namespace_pare"
    else
        get_pod_command="kubectl"
    fi
    pod_list=$($get_pod_command get pod  --no-headers|awk '{print $1}'|grep "$pod_name_para"|xargs)
    #check wemeet-controller pod status
    if [ -n "$pod_list" ];then
        exec_code=0
        for pod_name in $pod_list; do
            if $get_pod_command exec -t "$pod_name" -- netstat -n|awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}' >/dev/null 2>&1;then
                conn_status=$($get_pod_command exec -t "$pod_name" -- netstat -n|awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'|xargs)
                print_log "$INFO" "OK collection pod $pod_name tcp connection status: $conn_status"
            else
                print_log "$ERROR" "Nok collection pod $pod_name tcp connection status: Fail"
                exec_code=1
            fi
        done
        return $exec_code
    else
        print_log "$ERROR" "Nok find pod $pod_name_para"
        return 1
    fi
}

########################
#     main program     #
########################
main "$@"