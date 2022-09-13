#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-process-zombie-amount.sh
# Description: a script to monitor process zombie amount
################################################################
#desc: amount zombie process
check_process_zombie()
{
    zomblecount=""
    zomblecount=$(ps aux |awk '{if($8 == "Z"){print $2,$11}}'|wc -l)
    echo $zomblecount
}
check_process_zombie 
