#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-ssh-subsystem-sftp.sh
# Description: a script to check if ssh subsystem sftp options is ok
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# desc: check ssh subsystem sftp
# input: none
# output: 1/0
function check_ssh_subsystem_sftp()
{
    print_log "INFO" "Check SSH Subsystem sFTP option."
    if sshd -T | grep -i Subsystem | grep -q -E "sftp-server|internal-sftp"; then
        print_log "INFO" "Check SSH Subsystem sFTP option is ok."
        return 0
    fi
    print_log "ERROR" "SSH subsystem SFTP option not turned on, please execute scripts init-ssh-subsystem-sftp.sh repair."
    return 1
}


########################
#     main program     #
########################
check_ssh_subsystem_sftp
