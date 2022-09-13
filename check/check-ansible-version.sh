#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-ansible-version.sh
# Description: a script to check if ansible is installed on 
# local host and version is equal or greater than required
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



# desc: print how to use
print_usage() {
    print_log "INFO" "Usage: $baseName <ansible-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 2.9.3"
}

# desc: check if input is valid
function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

function ver_compare() 
{
    test "$(echo -e "$1\n$2" | sort -rV | head -n 1)" == "$1";
}



check_ansible_version() {
    check_input "$@"
    requiredVersion="$1"


    print_log "INFO" "Check ansible version"
    if command -v ansible > /dev/null 2>&1 ; then
        currentVersion=$(ansible --version | grep ansible | head -1 | awk '{print $2}')
        print_log "INFO" "Current version: ${currentVersion}, required version: ${requiredVersion}"
        #rc=$(awk -v  ver1=$requiredVersion -v ver2=$currentVersion  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        if ! ver_compare "${currentVersion}" "${requiredVersion}"; then
            print_log "ERROR" "Nok"
            return 1
        else
            print_log "INFO" "Ok"
        fi
    else
        print_log "ERROR" "ansible command is not found in system env. Nok"
        return 1
    fi

}


########################
#     main program     #
########################
check_ansible_version "$@"
