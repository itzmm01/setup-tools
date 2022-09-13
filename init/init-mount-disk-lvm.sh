#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: init-mount-disk-lvm.sh
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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")
# desc: print how to use
print_usage(){
    print_log "INFO" "Usage: $baseName <fs_type> <dev_name> <path> [mount_option] [fs_option]"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName xfs /dev/vdb /data"
    print_log "INFO" "  $baseName xfs /dev/vdb /data noatime '-n ftype=1' "
}
# desc: check input
check_input(){
    if [ $# -le 2 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}
# desc: mount disk
# input: fs_type, dev_name, path, mount_option, fs_option
# output: 1/0
main(){
    #check
    check_input "$@"
    check_command pvs
    check_command lvdisplay
    check_command pvcreate
    check_command vgcreate
    check_command lvcreate
    check_command blkid
    #set local var
    local fs_type="$1"
    local dev_name="$2"
    local mnt_path="$3"
    local mnt_opt="$4"
    local fs_opt="$5"
    #check dev_name
    if ! [[ -b $dev_name ]]; then
        print_log "ERROR" "Nok. $dev_name not a block device."
        return 1
    fi
    if df -P | grep -q "^$dev_name";then
        print_log "ERROR" "Nok. $dev_name already mounted."
        return 1
    fi
    #check fs_type
    if [[ $fs_type = xfs ]]; then
        mkfscmd="mkfs.xfs -f"
    elif [[ $fs_type = ext4 ]]; then
        mkfscmd="mkfs.ext4 -F"
    else
        print_log "ERROR" "Nok. fstype:$fs_type not supported yet."
        return 1
    fi
    #check mount option
    [[ -n "$mnt_opt" ]] || mnt_opt="defaults,noatime,nodiratime"
    #check mount path
    if [[ -d "$mnt_path" ]]; then
        if df -P | grep -q "$mnt_path$"; then
            lvm_dev_name=$(df -P | grep "$mnt_path$"|awk '{print $1}')
            if lvdisplay "${lvm_dev_name}"|grep -q "VG Name";then
                vg_info=$(lvdisplay "${lvm_dev_name}"|grep "VG Name"|awk '{print $NF}')
                pv_info=$(pvs|grep -w "${vg_info}"|awk '{print $1}')
                if ! [[ ${pv_info} =~ ${dev_name} ]]; then
                    print_log "ERROR" "Nok. ${mnt_path} already mounted by ${pv_info}, not ${dev_name}"
                    return 1
                fi
                lvm_fs_type=$(blkid "${lvm_dev_name}" -s TYPE -o value)
                if ! [[ "${lvm_fs_type}" = "$fs_type" ]]; then
                    print_log "ERROR" "Nok. $dev_name current mount fs_type not $fs_type"
                    return 1
                fi
                if ! grep "${mnt_path}[[:space:]]\+" /etc/fstab|grep -vq ^#; then
                    [[ -n "$(tail -c1 /etc/fstab )" ]] && echo >>/etc/fstab
                    mount | grep "${mnt_path}[[:space:]]\+" | awk "{print \$1,\$3,\$5,'$mnt_opt 0 0'}" >>/etc/fstab
                fi
                print_log "INFO" "Ok. $dev_name lvm mount to $mnt_path"
                return 0
            fi
        fi
    fi
    mkdir -p "$mnt_path"
    blktype=$(blkid "$dev_name" -s TYPE -o value)
    #chceck disk fs_type
    lvm_name=$(echo "$mnt_path"|tr -t '/' '_'|tr -t '-' '_')
    vg_name="vg${lvm_name}"
    lv_name="lv${lvm_name}"
    #create lvm
    if [[ $blktype != "LVM2_member" ]];then
        if ! echo "y" |pvcreate "$dev_name"  >/dev/null 2>&1; then
            print_log "ERROR" "Nok. $dev_name create pv failed."
            return 1
        fi
    fi
    disk_vg_info=$(pvs|grep "$dev_name"|awk '{print $2}')
    if [[ $disk_vg_info = "lvm2" ]];then
        if ! vgcreate "$vg_name" "$dev_name"  >/dev/null 2>&1; then
            print_log "ERROR" "Nok. $dev_name create vg $vg_name failed."
            return 1
        fi        
    elif [[ $disk_vg_info != "$vg_name" ]];then
        vg_name="$disk_vg_info"
    fi
    if ! lvdisplay "$vg_name"|grep -q "LV Name";then
        if ! lvcreate -y -l 100%FREE -n "$lv_name" "$vg_name" >/dev/null 2>&1; then
            print_log "ERROR" "Nok. $dev_name create lv $lv_name failed."
            return 1
        fi  
    fi
    #format lvm
    lv_name=$(lvdisplay "${vg_name}"|grep "LV Name"|awk '{print $NF}')
    lvm_disk_path="/dev/${vg_name}/${lv_name}"
    lvm_mapper_path="/dev/mapper/$vg_name-$lv_name"
    disk_blktype=$(blkid "$lvm_disk_path" -s TYPE -o value)
    if [[ "$disk_blktype" != "$fs_type" ]]; then
        if ! $mkfscmd ${fs_opt} "$lvm_disk_path"  >/dev/null 2>&1; then
            print_log "ERROR" "Nok. format lvm device $lvm_disk_path failed."
            return 1
        fi
    fi
    #check fstab
    if ! grep -wq "^$lvm_mapper_path" /etc/fstab; then
        [[ -n "$(tail -c1 /etc/fstab )" ]] && echo >>/etc/fstab
        if ! echo "$lvm_mapper_path $mnt_path $fs_type $mnt_opt 0 0" >>/etc/fstab; then
            print_log "ERROR" "Nok. add mount lvm device $lvm_mapper_path to /etc/fstab failed."
            return 1
        fi
        if ! mount -a; then
            print_log "ERROR" "Nok. mount lvm device $lvm_mapper_path failed."
            return 1
        fi
    fi
    print_log "INFO" "Ok. $dev_name lvm mount to $mnt_path"
}
########################
#     main program     #
########################
main "$@"
