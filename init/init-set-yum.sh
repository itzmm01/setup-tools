#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-dns-server.sh
# Description: a script to set yum server
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "INFO" "Usage: $baseName <yum_name> <yum_server_address> [is_overwrite]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName centos http://localhost:8010/current/cos-rpm-repo false"
        exit 1
    fi
}

# input: yum_name, yum_server
# output: 1/0
function set_yum()
{
    check_input "$@"

    print_log "INFO" "set yum server"
    yum_name=$1
    yum_server=$2
    is_overwrite=${3:-"false"}
    if [ $is_overwrite != "true" ] && [ -f /etc/yum.repos.d/$yum_name.repo ]; then
        print_log "ERROR" "yum name is exist"
        print_log "ERROR" "yum server set failed"
        return 1
    fi
    cat > /etc/yum.repos.d/$yum_name.repo << EOF
[$yum_name]
name=$yum_name
baseurl=$yum_server
enabled=1
gpgcheck=0
EOF
    yum clean all > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_log "INFO" "yum server set ok"
        return 0
    else
        print_log "ERROR" "yum server set failed"
        return 1
    fi
}

########################
#     main program     #
########################
set_yum "$@"