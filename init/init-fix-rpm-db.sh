#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-fix-rpm-db.sh
# Description: a script to auto fix rpmdb error
################################################################


#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
function fix_rpmdb() {
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    if [ "$os_version" == "uos" ]; then 
        print_log "OK" "no support UOS"
        exit 0
    fi
    if rpm -qf /bin/bash |& grep -Eq 'BDB0|BDB1'; then
        print_log "INFO" "found rpmdb err, try to auto fix ..."
        /bin/rm -fr /var/lib/rpm/__db.*
        if rpm --rebuilddb; then
            print_log "INFO" "rpmdb fix ok"
            yum clean all
            return 0
        fi
        print_log "ERROR" "rpmdb fix failed"
        return 1
    fi
    print_log "INFO" "rpmdb ok"
    return 0
}

########################
#     main program     #
########################
fix_rpmdb
