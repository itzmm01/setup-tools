#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

get_datadisks() {
    # find all datadisks
    # input: target -- num / name
    # output: num / name
    # e.g.: get_datadisks num ; get_datadisks name
    local target="$1"
    local disks
    # get all disk device's type, name and mountpoint
    disks=$(lsblk -lpno type,name,mountpoint 2>/dev/null | grep -E '^disk|^part|^lvm|/$')
    # to findout all datadisks, we must exclude all disks/partitions/volumes used by sysdisk
    # sysdisk partition, /dev/vda1
    sysdisk_part=$(echo "$disks"|grep '/$'|awk '{print $2}'|tail -1)
    # sysdisk device path, /dev/vda1
    sysdisk_dev=$(realpath "$sysdisk_part" 2>/dev/null)
    # basename of sysdisk device, vda1
    sysdisk_basename=$(basename "$sysdisk_dev" 2>/dev/null)
    # ../../devices/pci0000:00/0000:00:04.0/virtio1/block/vda/vda1
    sysdisk_class=$(ls -l /sys/class/block/|grep "$sysdisk_basename$"|tail -1|awk '{print $NF}')
    # ../../devices/pci0000:00/0000:00:04.0/virtio1/block/vda
    sysdisk_base=$(dirname "$sysdisk_class" 2>/dev/null)
    # /sys/devices/pci0000:00/0000:00:04.0/virtio1/block/vda/stat
    if [ -f "/sys/class/block/$sysdisk_base/stat" ]; then
        # if stat file exists, sysdisk is a partition of block device vda
        sysdisk=$(basename "$sysdisk_base" 2>/dev/null)
    else
        # otherwise, sysdisk is not a partion
        sysdisk=$(basename "$sysdisk_class" 2>/dev/null)
    fi
    # if sysdisk is lv, findout all physical volumes used by sysdisk logical volume
    # these volumes cannot be used by datadisks
    sysdisk_ident="NULL"
    sysdisk_idents="NULL"
    sysdisk_type=$(echo "$disks"|grep '/$'|tail -1|awk '{print $1}')
    if [[ $sysdisk_type = lvm ]]; then
        vg=$(lvs "$sysdisk_part" 2>/dev/null|tail -1|awk '{print $2}')
        pv_s=$(pvs 2>/dev/null|grep -w "$vg"|awk '{print $1}')
        for pv in $pv_s; do
            pv_dev=$(realpath "$pv" 2>/dev/null)
            pv_basename=$(basename "$pv_dev" 2>/dev/null)
            pv_class=$(ls -l /sys/class/block/|grep "$pv_basename$"|tail -1|awk '{print $NF}')
            pv_base=$(dirname "$pv_class" 2>/dev/null)
            if [ -f "/sys/class/block/$pv_base/stat" ]; then
                sysdisk_ident=$(basename "$pv_base" 2>/dev/null)
            else
                sysdisk_ident=$(basename "$pv_class" 2>/dev/null)
            fi
            sysdisk_idents="$sysdisk_idents|$sysdisk_ident"
        done
    fi
    # so we can exclude all sysdisk related devices now.
    raw_datadisks=$(echo "$disks" | grep 'disk' | grep -Ev "$sysdisk_idents|$sysdisk|$sysdisk_part" | awk '{print $2}')
    pv_lst=$(echo NULL;pvs 2>/dev/null | grep -v PV | awk '{print $1}' | sed 's/[0-9]*$//' | tr '\n' '|' | sed 's/^|//;s/|$//')
    # also exclude devices already been used as lvm physical volumes
    datadisks=$(echo "$raw_datadisks" | grep -Ev "$pv_lst" | sort)
    datadisk_num=$(echo "$datadisks" | grep -v '^$' | wc -l)
    if [[ $target = name ]]; then
        echo "$datadisks"
    else
        echo "$datadisk_num"
    fi
}

is_digit() {
    if [[ "$1" =~ ^([1-9][0-9]{0,14}|0)$ ]]; then
        return 0
    fi
    return 1
}

is_mounted() {
    local disks=$@
    local count=$#
    local total=0
    local disk
    for disk in ${disks}; do
        if mount | grep -q "^${disk}[[:space:]]\+"; then
            total=$((total+1))
        elif mount | grep -q "^${disk}[0-9][[:space:]]\+"; then
            total=$((total+1))
        else
            print_log "ERROR" "$disk not mount"
        fi
    done
    if [[ $total -eq $count ]]; then
        return 0
    fi
    return 1
}


# output: 1/0
check_rawdisk_mount_num() {
    real_disknum=$(get_datadisks num)
    datadisks=$(get_datadisks name)
    is_digit "$real_disknum" || {
        print_log "ERROR" "get disk num failed"
        return 1
    }
    if is_mounted $datadisks; then
        print_log "INFO" "all $real_disknum disks($datadisks)  mounted"
        return 0
    fi
    print_log "ERROR" "not all $real_disknum disks mounted"
    return 1
}

check_rawdisk_mount_num
