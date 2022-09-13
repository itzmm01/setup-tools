#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mem-buffers-size.sh
# Description: a script to monitor memory buffers size 
################################################################
# get memory buffers size
mem_buffers()
{
    buffers=$(cat /proc/meminfo |grep Buffers |awk '{print $2}')
    echo "$buffers"
}
mem_buffers
