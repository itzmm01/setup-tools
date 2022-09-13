#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-free-size.sh
# Description: a script to monitor memory free size 
################################################################
# get memory free size
mem_free()
{
    free=$(cat /proc/meminfo |grep MemFree |awk '{print $2}')
    echo "$free"
}
mem_free
