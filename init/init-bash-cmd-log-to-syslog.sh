#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-bash-cmd-log-to-syslog.sh
# Description: a script to add cmd logto syslog
################################################################

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

main() {
    [ -f /etc/bashrc ] && source /etc/bashrc
    if readonly | grep -q HISTSIZE; then
        print_log "INFO" "HISTSIZE is readonly, quit."
        return
    fi
    if readonly | grep -q HISTTIMEFORMAT; then
        print_log "INFO" "HISTTIMEFORMAT is readonly, quit."
        return
    fi
    if readonly | grep -q PROMPT_COMMAND; then
        print_log "INFO" "PROMPT_COMMAND is readonly, quit."
        return
    fi
    cat >/etc/profile.d/udc_bash_cmdlog.sh <<\EOF
_cmdlogger() {
    unset HISTCONTROL
    export HISTSIZE=3000
    export HISTTIMEFORMAT="[%F %T] [`who am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'`] "
    export PROMPT_COMMAND='\
    if [ -z "$OLD_PWD" ]; then
        export OLD_PWD=$(pwd);
    fi;
    if [ ! -z "$LAST_CMD" ] && [ "$(history 1)" != "$LAST_CMD" ]; then
        logger `whoami`_shell_cmd "[$OLD_PWD]$(history 1)"
    fi;
    export LAST_CMD="$(history 1)";
    export OLD_PWD=$(pwd);'
}
trap _cmdlogger DEBUG
EOF
    if [[ -s /etc/profile.d/udc_bash_cmdlog.sh ]]; then
        print_log "INFO" "cmdlog init ok"
        return 0
    fi
    print_log "ERROR" "cmdlog init failed"
    return 1
}

main
