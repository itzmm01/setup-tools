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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}


fix_version_id() {
    local verid=$1
    if grep -q "VERSION_ID=\"$verid\"" /etc/os-release; then
        print_log "INFO" "VERSION_ID already $verid"
        return 0
    fi
    [[ -n "$(tail -c1 /etc/os-release )" ]] && echo >>/etc/os-release
    if echo "VERSION_ID=\"$verid\"" >>/etc/os-release; then
        print_log "INFO" "VERSION_ID fixed as $verid"
        return 0
    fi
    print_log "ERROR" "VERSION_ID not fixed"
    return 1
}
# output: 1/0
main() {
    if ! [ -f /etc/os-release ]; then
        print_log "ERROR" "/etc/os-release is not exists"
        return 1
    fi
    # NeoKylin V7Update6
    if [[ -f /etc/neokylin-release ]] && grep -q 'VERSION_ID="V7' /etc/os-release 2>/dev/null; then
        fix_version_id 7
    # kylin V10
    elif [[ -f /etc/kylin-release ]] && grep -q 'VERSION_ID="V10' /etc/os-release 2>/dev/null; then
        fix_version_id 10
    fi
}


########################
#     main program     #
########################
main
