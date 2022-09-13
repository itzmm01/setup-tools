#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-system-umask.sh
# Description: a script to monitor system umask 
################################################################

# get system system_umask
system_umask()
{
    uamsk=""
    uamsk=$(umask)
    echo "$uamsk"
}

system_umask
