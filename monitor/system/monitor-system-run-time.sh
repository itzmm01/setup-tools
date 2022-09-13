#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-system-run-time.sh
# Description: a script to monitor system run time 
################################################################

# get system run time
system_run_time()
{
    runTime=""
    runTime=$(awk -F. '{print $1}' /proc/uptime)
    echo "$runTime"
}

system_run_time
