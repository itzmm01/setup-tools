#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-k8s-version.sh
# Description: a script to check if current k8s server version
# is the same as the input version
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
    print_log "INFO" "Desc: Check if current k8s version meets any from the input list"
    print_log "INFO" "Usage: $baseName <k8s-version-list>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName v1.16.3"
    print_log "INFO" "  $baseName v1.16.3 v1.16.6"
}


check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "At least one argument is required."
        print_usage
        exit 1
    fi
}

check_k8s_version()
{
    if [ "$1" != "$2" ]; then
        return 1
    fi
    return 0
}

main()
{
    check_input "$@"
    print_log "INFO" "Check k8s version"
    if command -v kubectl > /dev/null 2>&1 ; then
        currentVersion=$(kubectl version | grep "Server Version" | cut -d , -f 3  | cut -d : -f 2 | sed 's/\"//g' | cut -d '-' -f 1)
        requiredVersions="$*"
        print_log "INFO" "Current version: ${currentVersion}, required version(s): ${requiredVersions}"
        # check if at least one version is ok
        for version in "$@"; do
            if check_k8s_version "$currentVersion" "${version}"; then
                print_log "INFO" "${version} matched. Ok"
                return 0
            fi
        done
        print_log "ERROR" "No version matched. Nok"
        return 1
    else
        print_log "ERROR" "kubectl command is not found in system env. Nok"
        return 1
    fi

    return 0
}


########################
#     main program     #
########################
main "$@"
