#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mem-cached-size.sh
# Description: a script to monitor memory cachede size 
################################################################
# get memory cached size
mem_cached()
{
    cached=$(cat /proc/meminfo |grep Cached |awk 'NR==1 {print $2}')
    echo "$cached"
}
mem_cached
