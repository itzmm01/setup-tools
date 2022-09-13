#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-mount-disk.sh
# Description: a script to mount disk
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")

# desc: mount disk
# input: fs_type, dev_name, path, mount_option, fs_option
# output: 1/0
mount_disk() {
    local fs_type="$1"
    local dev_name="$2"
    local mnt_path="$3"
    local mnt_opt="$4"
    local fs_opt="$5"
    [[ -n "$mnt_opt" ]] || mnt_opt="defaults,noatime,nodiratime"
    if df -P | grep -q "$mnt_path$"; then
        local blktype
        blktype=$(blkid "$dev_name" -s TYPE -o value)
        if ! [[ "$blktype" = "$fs_type" ]]; then
            print_log ERROR "$dev_name current fs_type not $fs_type"
            return 1
        fi
        local mnt_disk
        mnt_disk=$(mount | grep "${mnt_path}[[:space:]]\+" | awk '{print $1}')
        if ! [[ $mnt_disk = "$dev_name" ]]; then
            print_log ERROR "$mnt_path already mounted by $mnt_disk, not $dev_name"
            return 1
        fi
        if ! grep -q "${mnt_path}[[:space:]]\+" /etc/fstab; then
            [[ -n "$(tail -c1 /etc/fstab )" ]] && echo >>/etc/fstab
            mount | grep "${mnt_path}[[:space:]]\+" | awk "{print \$1,\$3,\$5,'$mnt_opt 0 0'}" >>/etc/fstab
        fi
        return 0
    fi
    [[ -d "$mnt_path" ]] || mkdir "$mnt_path"
    if [[ $fs_type = xfs ]]; then
        mkfscmd="mkfs.xfs -f"
    elif [[ $fs_type = ext4 ]]; then
        mkfscmd="mkfs.ext4 -F"
    else
        print_log ERROR "fstype:$fs_type not supported yet."
        return 1
    fi

    if ! [[ -b $dev_name ]]; then
        print_log ERROR "$dev_name not a block device."
        return 1
    fi
    blktype=$(blkid "$dev_name" -s TYPE -o value)
    if ! [[ "$blktype" = "$fs_type" ]]; then
        $mkfscmd $fs_opt "$dev_name"
    fi
    if ! grep -wq "^$dev_name" /etc/fstab; then
        [[ -n "$(tail -c1 /etc/fstab )" ]] && echo >>/etc/fstab
        echo "$dev_name $mnt_path $fs_type $mnt_opt 0 0" >>/etc/fstab
    fi
    systemctl daemon-reload >/dev/null 2>&1
    mount -a
}


########################
#     main program     #
########################
[[ $# -ge 3 ]] || {
    echo "usage: $baseName <fs_type> <dev_name> <path> [mount_option] [fs_option]"
    exit 1
}
mount_disk "$@"
