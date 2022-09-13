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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <umask>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  0022"
}

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

main() {
    check_input "$@"
    local v=$1
    local umask_non_login_shell
    local umask_login_shell
    umask_non_login_shell=$(bash -c 'source /etc/bashrc 2>/dev/null;umask')
    umask_login_shell=$(source /etc/profile 2>/dev/null;umask)
    if [[ $umask_non_login_shell = "$v" ]] && [[ $umask_login_shell = "$v" ]]; then
        print_log "INFO" "umask ok"
        return 0
    fi
    print_log "ERROR" "umask err: login shell:$umask_login_shell , non-login shell:$umask_non_login_shell"
    return 1
}


########################
#     main program     #
########################
main "$@"
