#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-cpu-core-id-amount.sh
# Description: a script to monitor cpu processor amount
################################################################
#desc: get cpu core id amount
cpu_core_id_amount()
{
    amount=""
    amount=$(cat /proc/cpuinfo |grep "core id" | sort|uniq |wc -l)
    echo "$amount"
}

cpu_core_id_amount 
