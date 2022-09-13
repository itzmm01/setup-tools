#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-block-device-capacity.sh
# Description: a script to check if block device is capacity is ok
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
check_input()
{
    if [ $# -ne 2 ]; then
        print_log "INFO" "Usage: $baseName <devname> <capacity>"
        print_log "INFO" "Example:"
        print_log "INFO" "Eg: $baseName /dev/sda1 500GB"
        print_log "INFO" "unit support: MB,GB,TB"
        print_log "INFO" "MB is used by default."
        exit 1
    fi
}

# desc: check block device capacity
# input: devname capacity
# output: 1/0
check_block_device_capacity()
{
    check_input "$@"
    local devname=$1
    local capacity=$2
    print_log "INFO" "Check if capacity of block device $devname is ok"
    dev=$(echo "$devname" | awk -F'/' '{ print $NF }')
    real_cap=$(lsblk -lb -o NAME,SIZE | awk -v dev="$dev" '{if($1==dev) print ($2/1024/1024)}')
    if [[ -z "$real_cap" ]]; then
        print_log "ERROR" "The disk $devname doesn't exist in the system."
        return 1
    fi
    print_log "INFO" "Compare block device is $devname."
    disk_capacity_compare "$real_cap" "$capacity"
    exit $?
}

disk_capacity_compare()
{
    local real_cap=$1
    local capacity=$2
    local compare_cap_return=0
    MB=$(echo "$capacity"|grep -E -i "m$|mb$"|awk -F'm|M' '{print $1}')
    GB=$(echo "$capacity"|grep -E -i "g$|gb$"|awk -F'g|G' '{print $1}')
    TB=$(echo "$capacity"|grep -E -i "t$|tb$"|awk -F't|T' '{print $1}')
    if [[ -n $MB ]];then
        compare_cap=$MB
        compare_cap "$real_cap" "$compare_cap"
        compare_cap_return=$?
        log_real_cap=$real_cap
        print_log "INFO" "Current: ${log_real_cap}M, required: ${capacity}"
        return ${compare_cap_return}
    elif [[ -n $GB ]];then
        #输入的数值是GB单位,转换为MB再进行比较
        compare_cap=$((GB*1000))
        compare_cap "$real_cap" "$compare_cap"
        compare_cap_return=$?
        log_real_cap=$((real_cap/1000))
        print_log "INFO" "Current: ${log_real_cap}G, required: ${capacity}"
        return ${compare_cap_return}
    elif [[ -n $TB ]];then
        #输入的数值是TB单位,转换为MB再进行比较
        compare_cap=$((TB*1000*1000))
        compare_cap "$real_cap" "$compare_cap"
        compare_cap_return=$?
        log_real_cap=$((real_cap/1000000))
        print_log "INFO" "Current: ${log_real_cap}T, required: ${capacity}"
        return ${compare_cap_return}
    else
        #输入的数值未带单位,则默认为MB
        compare_cap=$capacity
        compare_cap "$real_cap" "$compare_cap"
        compare_cap_return=$?
        print_log "INFO" "Current: ${real_cap}M, required: ${capacity}M"
        return ${compare_cap_return}
    fi
}

compare_cap()
{
    local real_cap=$1
    local compare_cap=$2
    if [[ $real_cap -ge $compare_cap ]]
    then
        #实际磁盘容量比输入的容量大,满足容量要求
        print_log "INFO" "Ok."
        return 0
    else
        #实际磁盘容量比输入的容量小,不满足容量要求
        print_log "WARNING" "Nok."
        return 1
    fi
}

########################
#     main program     #
########################
check_block_device_capacity "$@"
