#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-host-ipv6-enable.sh
# Description: a script to enable host ipv6 protocol
################################################################
#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# input: none
# output: 1/0
enable_ipv6_grub() {
    if grep -q 'ipv6.disable' /etc/default/grub; then
        sed -i 's/ipv6.disable=1/ipv6.disable=0/' /etc/default/grub
    else
        sed -i -e 's|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"ipv6.disable=0 |g' /etc/default/grub
    fi
    if grub2-mkconfig -o /boot/grub2/grub.cfg; then
        print_log "INFO" "OK, please reboot os effect ipv6 enable."
        return 0
    fi
    print_log "ERROR" "Nok set ipv6.disable=0"
    return 1
}

enable_ipv6_sysctl() {
    [[ -n "$(tail -c1 /etc/sysctl.conf)" ]] && echo >>/etc/sysctl.conf
    sed -i '/^net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/^net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
    sed -i '/^net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf
    echo "net.ipv6.conf.all.disable_ipv6 = 0" >>/etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 0" >>/etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 0" >>/etc/sysctl.conf
}

ipv6_enable() {
    print_log "INFO" "Enable host IPv6 protocol"
    if ! [[ -d /proc/sys/net/ipv6 ]]; then
        enable_ipv6_grub
        return $?
    fi
    enable_ipv6_sysctl
    if echo "0" > /proc/sys/net/ipv6/conf/all/disable_ipv6; then
        print_log "INFO" "The current IPv6 protocol enabled"
        return 0
    fi
    print_log "ERROR" "enable IPv6 protocol failed"
    return 1
}

########################
#     main program     #
########################
ipv6_enable
