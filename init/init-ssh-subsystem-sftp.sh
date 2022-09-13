#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-ssh-subsystem-sftp.sh
# Description: a script to init ssh subsystem sftp options
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

# desc: init ssh subsystem sftp
# input: none
# output: 1/0
function init_ssh_subsystem_sftp()
{
    print_log "INFO" "Set SSH Subsystem sFTP option."
    if sshd -T | grep -i Subsystem | grep -q -E "sftp-server|internal-sftp"; then
        print_log "INFO" "SSH Subsystem sFTP option is ok, skip this step."
        return 0
    else
        local ssh_config=/etc/ssh/sshd_config
        [[ -n "$(tail -c1 ${ssh_config})" ]] && echo "" >> ${ssh_config}
        echo "Subsystem sftp internal-sftp" >> ${ssh_config}
        systemctl restart sshd
        print_log "INFO" "Set SSH Subsystem sFTP option success."
        return 0
    fi 
    print_log "ERROR" "Set SSH Subsystem sFTP option failed."
    return 1
}


########################
#     main program     #
########################
init_ssh_subsystem_sftp
