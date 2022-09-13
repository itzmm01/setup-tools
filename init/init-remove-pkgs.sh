#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}


# desc: remove pkgs for system
# input: pkgname
# output: 0/1
main() {
    local pkg="$@"
    local cmd
    [ -x /usr/bin/yum ] && cmd=yum || cmd=apt-get
    if $cmd -y remove "$pkg"; then
        print_log "INFO" "remove $pkg success."
        return 0
    fi
    print_log "ERROR" "remove $pkg failed."
    return 1
}


########################
#     main program     #
########################
main "$@"
