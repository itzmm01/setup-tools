#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-memory-used-utilization.sh
# Description: a script to monitor memory used 
################################################################
# get memory used
mem_used()
{
    total=$(cat /proc/meminfo |grep MemTotal |awk '{print $2}')
    free=$(cat /proc/meminfo |grep MemFree |awk '{print $2}')
    cached=$(cat /proc/meminfo |grep Cached |awk 'NR==1 {print $2}')
    buffers=$(cat /proc/meminfo |grep Buffers |awk '{print $2}')
    swap=$(cat /proc/meminfo |grep SwapCached |awk '{print $2}')
    used=$(expr $total - $free)
    used=$(expr $used - $cached)
    used=$(expr $used - $buffers)
    used=$(expr $used - $swap)
    mem_used_percent=$(echo "scale = 2; ($used / $total)*100" | bc)
    #$mem_used_percent=`echo $mem_used_percent|grep -o '[0-9]\+'|awk 'NR==1'`
    echo "$mem_used_percent"
}
mem_used 
