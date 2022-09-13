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


tune_cpufreq() {
    if systemctl is-enabled tune-cpufreq >/dev/null 2>&1; then
        systemctl start tune-cpufreq
        if [ $? -eq 0 ];then
            print_log "INFO" "OK"
            return 0
        fi
    fi
    cat >/etc/systemd/system/tune-cpufreq.service << "EOF"
[Unit]
Description=Tune cpufreq to performance mode
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo -n performance > $f;done;echo'

[Install]
WantedBy=basic.target
EOF
    systemctl daemon-reload && systemctl enable tune-cpufreq && systemctl start tune-cpufreq
    if [ $? -eq 0 ];then
       print_log "INFO" "OK"
    else
       print_log "ERROR" "Nok"
    fi
}

tune_cpufreq
