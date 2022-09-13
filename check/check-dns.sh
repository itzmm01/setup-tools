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


# desc: check dns is available
# output: 1/0
check_dns() {
    if ! grep -i nameserver /etc/resolv.conf | grep "[0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}"  >/dev/null 2>&1; then
        print_log "ERROR" "/etc/resolv.conf not config"
        return 1
    fi
    if [[ -f "$commonDir/dig/dig.$(uname -i)" ]]; then
        digcmd="$commonDir/dig/dig.$(uname -i)"
        chmod +x "$digcmd"
        ns1=$(grep -E '^nameserver[[:space:]]+[0-9.]+$' /etc/resolv.conf | head -1 | awk '{print $2}')
        if $digcmd @$ns1 qq.com 2>/dev/null | grep -qi 'timeout'; then
            print_log "ERROR" "ns:$ns1 dead"
            return 1
        fi
        qtime=$($digcmd @$ns1 qq.com | grep -Eo 'time: [0-9.]+ms')
        print_log "INFO" "DNS is ok($qtime)"
        return 0
    fi
    if ! which dig  >/dev/null 2>&1; then
        print_log "ERROR" "dig not installed"
        return 1
    fi
    if dig qq.com >/dev/null 2>&1; then
        print_log "INFO" "DNS is Ok"
        return 0
    fi
    print_log "ERROR" "DNS is not ok"
    return 1
}

########################
#     main program     #
########################
check_dns
