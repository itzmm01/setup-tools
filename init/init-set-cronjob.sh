#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-cronjob.sh
# Description: a script to set cron
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
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "INFO" "Usage: $baseName <job_name> <job>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName sync_time \"*/20 * * * * /usr/sbin/ntpdate time1.cloud.tencent.com > /dev/null  2>&1 &\""
        exit 1
    fi
}
# input: name, content
# output: 1/0
set_cron() {
    check_input "$@"
    local name="$1"
    shift
    local content="$*"
    cat >/etc/cron.d/udc-init-$name<<EOF
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SHELL=/bin/bash
$content
EOF
    chmod 600 /etc/cron.d/udc-init-$name 
    print_log "INFO" "cronjob set ok"
}


########################
#     main program     #
########################
set_cron "$@"
