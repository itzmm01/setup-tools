#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-swap-cached-size.sh
# Description: a script to monitor swap cached size 
################################################################
# get  swap cdched size
mem_swap_cached()
{
    swapCached=$(cat /proc/meminfo |grep SwapCached |awk '{print $2}')
    echo "$swapCached"
}
mem_swap_cached
