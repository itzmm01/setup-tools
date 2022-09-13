#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-cpu-physical-id-amount.sh
# Description: a script to monitor cpu physical id amount
################################################################
#desc: get cpu physical id amount
cpu_physical_id_amount()
{
    amount=""
    amount=$(cat /proc/cpuinfo |grep "physical id" | sort|uniq |wc -l)
    echo "$amount"
}

cpu_physical_id__amount 
