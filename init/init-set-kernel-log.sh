#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-set-kernel-log.sh
# Description: a script to init kernel log
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

# desc: init kernel log
# input: path
# output: 1/0
function main()
{
    if [[ ! -e /etc/rsyslog.d/kern.conf ]]; then
        cat <<EOF >/etc/rsyslog.d/kern.conf
\$ModLoad imklog
kern.*                    /var/log/kern
EOF
        [[ $? -eq 0 ]] && systemctl restart rsyslog 
        if [[ $? -ne 0 ]];then
            print_log "ERROR" "init kern log: fail"
            return 1
        fi
    fi
    if ! grep -q /var/log/kern /etc/logrotate.d/syslog; then
        cat <<EOF >/etc/logrotate.d/syslog
/var/log/cron
/var/log/maillog
/var/log/messages
/var/log/secure
/var/log/spooler
/var/log/kern
{
    missingok
    sharedscripts
    postrotate
/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
    endscript
}
EOF
        if [[ $? -ne 0 ]];then
            print_log "ERROR" "init kern log: fail"
            return 1
        fi
    fi
    print_log "INFO" "init kern log: ok"
    return 0
}
########################
#     main program     #
########################
main
