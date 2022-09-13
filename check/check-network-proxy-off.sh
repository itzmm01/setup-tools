#!/bin/bash

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
baseName=`basename $0`

function check_network_proxy()
{
    #
    print_log "INFO" "Check network proxy is off"
    if [ -z $http_proxy -a -z $https_proxy ]; then
        print_log "INFO" "Ok network proxy is off"
        return 0
    fi
    print_log "ERROR" "proxy is $http_proxy or $https_proxy"
    return 1
}


check_network_proxy
