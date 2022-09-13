#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-process-runing-amount.sh
# Description: a script to monitor process zombie count
################################################################
#desc: count zombie process
check_process_running()
{
    runningcount=""
    runningcount=$(ps aux |awk '{if($8 == "R"){print $2,$11}}'|wc -l)
    echo $runningcount
}
check_process_running 
