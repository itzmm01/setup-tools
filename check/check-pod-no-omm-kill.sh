#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-pod-status.sh
# Description: a script to check pod status
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
#desc: desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
# output: 1/0
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
    pod_list=$($get_pod_command get pod |grep "$pod_name_para"|awk '{print $1}'|xargs)
    #check wemeet-controller pod status
    if [ -n "$pod_list" ];then
        exec_code=0
        for pod_name in $pod_list; do
            if ! $get_pod_command exec -t "$pod_name" -- dmesg -T | grep Kill ;then
                print_log "$INFO" "OK pod $pod_name not omm kill"
            else
                omm_kill_info=$($get_pod_command exec -t "$pod_name" -- dmesg -T | grep Kill -C 100)
                print_log "$ERROR" "Nok pod $pod_name has omm kill"
                echo "omm_kill_info"
                exec_code=1
            fi
        done
        return $exec_code
    else
        print_log "ERROR" "Nok find pod $pod_name_para"
        return 1
    fi
}

########################
#     main program     #
########################
main "$@"
