#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-mem-available-size.sh
# Description: a script to monitor memory available size 
################################################################
# get memory cached size
mem_available()
{
    available=$(cat /proc/meminfo |grep MemAvailable |awk 'NR==1 {print $2}')
    echo "$available"
}
mem_available
