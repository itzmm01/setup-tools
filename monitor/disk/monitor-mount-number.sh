#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: monitor-mount-number.sh
# Description: a script to monitor mount number
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function main()
{
    if !which mount >/dev/null 2>&1; then
        print_log "ERROR" "Nok mount command not installed"
        exit 1
    fi
    mount_count=$(mount|wc -l)
    echo $mount_count
}

########################
#     main program     #
########################
main