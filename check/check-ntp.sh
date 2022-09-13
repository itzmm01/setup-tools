#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-ntp.sh
# Description: check if ntp is enabled and synchronized
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
baseName=$(basename "$0")

# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName "
    print_log "INFO" "e.g. $baseName"
}

# desc: check if ntp is ok
# input: lang
# output: 1/0
check_ntp() {
    case "$1" in
        "-h"|"help"|"--help")
            print_usage
            ;;
        *)
            print_log "INFO" "Check ntp status"
            ntp_sync=$(timedatectl status|grep "NTP synchronized\|System clock synchronized"|awk '{print $NF}')
            print_log "INFO" "synchronized: ${ntp_sync}"
            if [[ "${ntp_sync}" == "yes" ]]; then
                print_log "INFO" "Ok"
                return 0
            fi
            print_log "ERROR" "Nok"
            return 1
            ;;
    esac
}

check_ntp "$@"
