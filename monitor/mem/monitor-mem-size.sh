#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mem-size.sh
# Description: a script to monitor memory size 
################################################################
# get memory size
mem_total()
{
    total=$(cat /proc/meminfo |grep MemTotal |awk '{print $2}')
    echo "$total"
}
mem_total
