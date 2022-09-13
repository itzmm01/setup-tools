#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: init-umount-disk.sh
# Description: a script to umount disk
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
    currentTime=$(date "+%F %T")
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <dev_name>"
    print_log "INFO" "  init-umount-disk:  dev_name"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  /dev/vdb"
}

check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

#desc:check command exist
function check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}

function disk_used_by_lvm()
{
    local dev_name=$1
    check_command blkid
    blk_info=$(blkid | grep "${dev_name}" | awk '{print $1}' | awk -F ":" '{print $1}')
    if [[ -z $blk_info ]]; then
      return 0
    fi

    local disk_in_lvm=0
    for blk_disk in $blk_info; do
      blktype=$(blkid "$blk_disk" -s TYPE -o value)
      if [[ $blktype = "LVM2_member" ]]; then
        disk_in_lvm=1
        break
      fi
    done
    return $disk_in_lvm
}

function umount_disk()
{
    local dev_name=$1
    dev_name_mount_status=$(df -P | grep "^$dev_name" | awk '{print $NF}')
    # set umount disk $dev_name
    if [[ -n "$dev_name_mount_status" ]];then
        for mnt_path in $dev_name_mount_status;do
            mnt_disk=$(df -P | grep "$mnt_path$" | awk '{print $1}')
            # set umount disk $dev_name
            umount "$mnt_path"
            if [[ $? -eq 0 ]];then
                print_log "INFO" "umount disk $mnt_disk from $mnt_path: ok"
            else
                print_log "ERROR" "umount disk $mnt_disk from $mnt_path: fail"
                return 1
            fi
            # set umount disk $dev_name to fstab
            mnt_path_fstab=$(grep "$mnt_path" /etc/fstab|awk '{print $1,$2}'|grep "$mnt_path$"|awk '{print $1}'|grep -v ^#|head -n 1)
            if [[ -n "$mnt_path_fstab" ]];then
                sed -i "s|^$mnt_path_fstab|#$mnt_path_fstab|g" /etc/fstab 
                if [[ $? -ne 0 ]];then
                    print_log "ERROR" "umount disk $mnt_disk to fstab: fail"
                    return 1
                fi
                print_log "INFO" "umount disk $mnt_disk to fstab: ok"
            fi
        done
    else
        print_log "INFO" "$dev_name path not mount"
        return 0
    fi
}

function umount_lvm()
{
    local disk_name=$1
    check_command pvdisplay
    check_command vgs
    vg_info=$(pvdisplay "$disk_name" | grep "VG Name"|awk '{print $NF}' | grep -v "Name")
    pv_num=$(vgs | grep "$vg_info" | awk '{print $2}')
    lv_num=$(vgs | grep "$vg_info" | awk '{print $3}')
    # vg used by one more lvs
    if [[ $lv_num -gt 1 ]]; then
        print_log "ERROR" "Nok, find $lv_num lv using $vg_info."
        exit 1
    fi
    # pv in one more vgs
    if [[ $pv_num -gt 1 ]]; then
        print_log "ERROR" "Nok, find $pv_num pv in $vg_info."
        exit 1
    fi
    dev_info=$(blkid | grep "$vg_info"|awk -F ":" '{print $1}')
    umount_disk "$dev_info"
    return $?
}

# desc: umount disk
# input: path
# output: 1/0
function main()
{
    check_input "$@"
    local disk_dev_name="$1"
    # check disk
    if [[ -b $disk_dev_name ]]; then
        check_command lsblk
        part_num=$(lsblk -l "${disk_dev_name}" | awk '{print $6}' | grep -c "part")
        lvm_num=$(lsblk -l "${disk_dev_name}" | awk '{print $6}' | grep -c "lvm")
        # disk parted and any partition used by lvm, exit
        if [[ $part_num -gt 0 ]] && [[ $lvm_num -gt 0 ]]; then
            print_log "ERROR" "umount disk $disk_dev_name fail, disk partitions used by lvm."
            exit 1
        fi
        # check disk used by lvm
        disk_used_by_lvm "$disk_dev_name"
        if [[  $? -eq 1 ]]; then
            # used by lvm
            print_log "INFO" "${disk_dev_name} is used by lvm."
            umount_lvm "$disk_dev_name"
            if [[ $? -ne 0 ]]; then
                print_log "ERROR" "Nok, umount disk $disk_dev_name from lvm failed."
                exit 1
            fi
        else
          umount_disk "$disk_dev_name"
        fi
    else
        print_log "ERROR" "Nok, $disk_dev_name not a block device."
        return 1
    fi
}
########################
#     main program     #
########################
main "$@"
