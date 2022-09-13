#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
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

main() {
    print_log "INFO" "Disable useless default service"
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    if [ "$os_version" == "uos" ]; then
        return 0
    fi
    for serv in tuned irqbalance; do
        systemctl stop $serv >/dev/null 2>&1&& systemctl disable $serv >/dev/null 2>&1 \
        && print_log "INFO" "Disable useless default service $serv: ok" || print_log "INFO" "Disable useless default service $serv: failed"
        
    done
    return 0
}

########################
#     main program     #
########################
main
