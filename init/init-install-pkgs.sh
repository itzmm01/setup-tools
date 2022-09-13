#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-install-pkgs.sh
# Description: a script to install sys pkgs
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


# name of script
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <pkgs>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName pkgs;"
        print_log "INFO" "  $baseName pkgs1 pkgs2 pkgs3"
        exit 1
    fi
}
# desc: install pkgs
# input: pkg_names
# output: 1/0
install_pkgs() {
    check_input "$@"
    local pkgs="$@"
    [ -x /usr/bin/yum ] && install_cmd=yum || install_cmd=apt-get
    [[ ${pkgs:(-4)} = '.rpm' ]] && install=localinstall || install=install
    $install_cmd $install -y $pkgs
    return $?
}


########################
#     main program     #
########################
install_pkgs "$@"
