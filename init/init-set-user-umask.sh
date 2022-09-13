#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-user-umask.sh
# Description: a script to set timezone
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
        print_log "INFO" "Usage: $baseName <user> <umask>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName root 0022"
        exit 1
    fi
}
# desc: set user umask
# input: user, umask
# output: 1/0
set_umask() {
    check_input "$@"
    local user="$1"
    local mask="$2"
    cat >/etc/profile.d/${user}-umask.sh <<EOF
if [ "\$USER" = $user ]; then
    if [ `echo $mask | grep -e "^[0-9][0-9][0-9][0-9]$"` ];then
        umask $mask
    else
        print_log "ERROR" "Nok"
    fi
fi
EOF
    if [ $? -eq 0 ];then
        print_log "INFO" "OK"
        return 0
    fi
    print_log "ERROR" "Nok"
}


########################
#     main program     #
########################
set_umask "$@"
