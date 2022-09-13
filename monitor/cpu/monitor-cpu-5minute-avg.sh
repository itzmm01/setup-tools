#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-cpu-5minute.sh
# Description: a script to monitor cpu 5 minute avg
################################################################
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}
# get cpu_info
cpu_avg_5()
{
    check_command uptime
    real_load_avg=$(uptime |awk '{print $(NF-1)}'| cut -d \, -f 1)
    echo "$real_load_avg"
}
########################
#     main program     #
########################
cpu_avg_5 
