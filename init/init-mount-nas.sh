#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-mount-nas.sh
# Description: a script to mount disk of nas type using nfs
################################################################



# name of script
baseName=$(basename "$0")

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

check_dev_mnt()
{
    path="$1"
    devName="$2"
    
    currentMntPt=$(mount | grep "${devName}[[:space:]]\+" | awk '{print $3}')
    if [ "${currentMntPt}" != "" ]; then
        print_log "INFO" "Device ${devName} is currently mounted on path ${currentMntPt}"
        if [ "${path}" != "${currentMntPt}" ]; then
            print_log "ERROR" "Current mount point ${currentMntPt} is not ${path}. Please check manually."
            return 1
        else
            print_log "INFO" "Path ${path} matched. Will exit now."
            exit 0
        fi
    fi
    print_log "INFO" "Device ${devName} is not mounted."
    return 0
}

check_path_partition()
{
    path="$1"
    requiredPartition="$2"

    print_log "INFO" "Check patition of path ${path}"

    # 1. Does path exist?
    if [ ! -d "${path}" ] ; then
        print_log "ERROR" "Path ${path} does not exist"
        return 1
    fi

    # no need to check remote device
    # 2. Does partition exist?
    #if ! fdisk -l "${requiredPartition}" >/dev/null 2>&1 ; then
    #    print_log "ERROR" "Partition ${requiredPartition} does not exist"
    #    return 1
    #else
    #    print_log "INFO" "Required partition: ${requiredPartition}"
    #fi

    # 3. Is partition correct?
    currentPartition=$(df "${path}" | sed 1d | awk '{print $1}')
    print_log "INFO" "Current partition: ${currentPartition}, Required partition: ${requiredPartition}"
    if [ "${currentPartition}" != "${requiredPartition}" ] ; then
        print_log "WARN" "Nok, not matched"
        return 1
    else
        print_log "INFO" "Ok, matched"
    fi
}


# desc: mount_disk_nas
# input: fs_type, dev_name, path, mount_option
# output: 1/0
mount_disk_nas() {

    # inputs
    local fs_type="nfs"
    local dev_name="$1"
    local mnt_path="$2"
    local mnt_opt="$3"
    # set default mount options: vers=3,nolock,proto=tcp
    [[ -n "${mnt_opt}" ]] || mnt_opt="vers=3,nolock,proto=tcp"

    # 1. Check if path exist
    if [ ! -d "${mnt_path}" ] ; then
        print_log "INFO" "Path ${mnt_path} does not exist yet, will try to create it first"
        mkdir -p "${mnt_path}"
    fi
    
    # 2. is device already mounted on another path?
    if ! check_dev_mnt "${mnt_path}" "${dev_name}"; then
        return 1
    fi

    # 3. is mount point already mounted?
    if df -Th "${mnt_path}" >/dev/null 2>&1; then
        currentMntPt=$(df -Th "${mnt_path}" | sed 1d  | awk '{print $7}')
        print_log "INFO" "Path ${mnt_path} is already mounted. Current mount point is ${currentMntPt}. Will check if it's mounted on target device ${dev_name}"
        if ! check_path_partition "${currentMntPt}" "${dev_name}"; then
            print_log "INFO" "Will try to mount path on target device"
            print_log "INFO" "Mount command: mount -t${fs_type} -o${mnt_opt} ${dev_name} ${mnt_path}"
            if ! mount -t"${fs_type}" -o"${mnt_opt}" "${dev_name}" "${mnt_path}"; then
                print_log "ERROR" "Mount failed."
                return 1
            fi
            print_log "INFO" "Mount succeeded."
        else
            print_log "INFO" "Will skip mount action"
        fi
    else
        print_log "INFO" "Path ${mnt_path} is not mounted. Will try to mount it on target device ${dev_name}"
        print_log "INFO" "Mount command: mount -t${fs_type} -o${mnt_opt} ${dev_name} ${mnt_path}"
        if ! mount -t"${fs_type}" -o"${mnt_opt}" "${dev_name}" "${mnt_path}"; then
            print_log "ERROR" "Mount failed."
            return 1
        fi
        print_log "INFO" "Mount succeeded."

    fi

    # 4. Is there any entry in /etc/fstab?
    # maybe the entry could be commented , but we will ignore it
    if ! grep -q "${mnt_path}[[:space:]]\+" /etc/fstab; then
        print_log "INFO" "${mnt_path} related entry not found in /etc/fstab, will add to /etc/fstab"
        echo "${dev_name} ${mnt_path} ${fs_type} ${mnt_opt} 0 0" >> /etc/fstab
    else
        print_log "INFO" "${mnt_path} related entry found in /etc/fstab, will skip adding to /etc/fstab"
    fi

}

########################
#     main program     #
########################
[[ $# -ge 2 ]] || {
    echo "usage: $baseName <fs_type> <dev_name> <path> [mount_option]"
    exit 1
}

mount_disk_nas "$@"
