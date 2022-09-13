#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: monitor-max-use-mem-process.sh
# Description: a script to monitor max use mem process
################################################################
function main()
{
    if !which ps >/dev/null 2>&1; then
        print_log "ERROR" "Nok ps command not installed"
        exit 1
    fi
    #max_process_info=$(ps aux|head -1;ps aux|grep -v PID|sort -rn -k +4|head -1)
    mem_used_percent=$(ps aux|grep -v PID|sort -rn -k +4|head -1|awk '{print $4}')
    echo "$mem_used_percent"
}
########################
#     main program     #
########################
main "$@"