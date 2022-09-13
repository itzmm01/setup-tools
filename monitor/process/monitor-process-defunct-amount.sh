#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: monitor-process-defunct-amount.sh
# Description:  a script to monitor process defunct amount
################################################################
# desc: amount defunct process
check_process_defunct() {
    defunctcount=""
    defunctcount=$(ps aux |awk '{if($8 == "D"){print $2,$11}}'|wc -l)
    echo $defunctcount
}

check_process_defunct
