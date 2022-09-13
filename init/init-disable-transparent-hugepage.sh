#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
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

disable_thp() {
    if systemctl is-enabled disable-transparent-huge-pages >/dev/null 2>&1; then
        systemctl start disable-transparent-huge-pages
        if [ $? -eq 0 ];then
            print_log "INFO" "OK"
            return 0
        fi
    fi
    cat >/etc/systemd/system/disable-transparent-huge-pages.service << "EOF"
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
EOF
    systemctl daemon-reload && systemctl enable disable-transparent-huge-pages && systemctl start disable-transparent-huge-pages
    if [ $? -eq 0 ];then
        print_log "INFO" "OK"
    else
        print_log "ERROR" "Nok"
    fi
}

disable_thp
