#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-process-stop-amount.sh
# Description: a script to monitor process stop amount
################################################################
#desc: amount stop process
check_process_stop()
{
    stopcount=""
    stopcount=$(ps aux |awk '{if($8 == "T"){print $2,$11}}'|wc -l)
    echo $stopcount
}
check_process_stop 
