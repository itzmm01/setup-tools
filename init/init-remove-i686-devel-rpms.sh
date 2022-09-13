#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
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


# desc: disable firewalld
# input: none
# output: none
main() {
    os_version=$(grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g')
    if [ "$os_version" == "uos" ]; then
        print_log "INFO" "remove i686 and devel rpms success."
        return 0
    fi

    if grep -q kylin /etc/os-release; then
        # shellcheck disable=SC2046
        if yum -y remove $(rpm -qa| grep -E 'i686|-devel'|grep -vE 'systemtap-sdt-devel|perl-Encode-devel|python2-devel|libxcrypt-devel|kernel-devel|glibc-devel|perl-devel'); then
            print_log "INFO" "remove i686 and devel rpms success."
            return 0
        fi
    else
        if yum -y remove '*i686' '*-devel'; then
            print_log "INFO" "remove i686 and devel rpms success."
            return 0
        fi
    fi
    print_log "ERROR" "remove i686 and devel rpms failed."
    return 1
}


########################
#     main program     #
########################
main
