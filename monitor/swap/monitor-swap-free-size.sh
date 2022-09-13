#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-swap-free-size.sh
# Description: a script to monitor  swap free size 
################################################################
# get swap free size
mem_swap()
{
    swapFree=$(cat /proc/meminfo |grep SwapFree |awk '{print $2}')
    echo "$swapFree"
}
mem_swap
