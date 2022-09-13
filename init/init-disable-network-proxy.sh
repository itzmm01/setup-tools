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

# input: none
# output: 1/0
function disable_network_proxy()
{
    #
    if [ -z $http_proxy -a -z $https_proxy ]; then
        print_log "INFO" "network proxy: disable"
        return 0
    else
        sed -i "s/^http_proxy/#http_proxy" /etc/profile
        sed -i "s/^https_proxy/#https_proxy" /etc/profile
        source /etc/profile && test -z $http_proxy && test -z $https_proxy  && print_log "INFO" "network proxy: disable" && return 0
        print_log "ERROR" "disable_network_proxy: failed"
        return 1
    fi
}

########################
#     main program     #
########################
disable_network_proxy