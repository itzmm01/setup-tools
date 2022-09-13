#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-process-sleep-amount.sh
# Description: a script to monitor process zombie count
################################################################
#desc: count zombie process
check_process_sleep()
{
    sleepcount=""
    sleepcount=$(ps aux |awk '{if($8 == "S"){print $2,$11}}'|wc -l)
    echo $sleepcount
}
check_process_sleep 
