#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-cpu-processor-amount.sh
# Description: a script to monitor cpu processor amount
################################################################
#desc: get cpu processor amount
cpu_processor_amount()
{
    amount=""
    amount=$(cat /proc/cpuinfo|grep "processor"|sort|uniq|wc -l)
    echo "$amount"
}

cpu_processor_amount 
