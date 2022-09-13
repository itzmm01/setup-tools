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

main() {
    if sysctl -p >/dev/null 2>&1; then
        print_log "INFO" "sysctl ok"
        return 0
    fi
    print_log "ERROR" "sysctl err"
    return 1
}


########################
#     main program     #
########################
main "$@"
