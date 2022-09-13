#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-swap-size.sh
# Description: a script to monitor  swap size 
################################################################
# get swap size
mem_swap()
{
    swap=$(cat /proc/meminfo |grep SwapTotal |awk '{print $2}')
    echo "$swap"
}
mem_swap
