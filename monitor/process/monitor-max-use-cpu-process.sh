#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: monitor-max-use-cpu-process.sh
# Description: a script to monitor max use cpu process
################################################################
function main()
{
    if !which ps >/dev/null 2>&1; then
        print_log "ERROR" "Nok ps command not installed"
        exit 1
    fi
    #max_process_info=$(ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head -1)
    cpu_used_percent=$(ps aux|grep -v PID|sort -rn -k +3|head -1|awk '{print $3}')
    echo "$cpu_used_percent"
}
########################
#     main program     #
########################
main "$@"