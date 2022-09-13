#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-clear-disk.sh
# Description:  clear umount disk
################################################################
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}


baseName=$(basename $0)
DISK_NAME="$1"


function print_usage()
{
    print_log "INFO" "Usage: $baseName <disk> "
    print_log "INFO" "Example:"
    print_log "INFO" "Usage: $baseName /dev/sdx"
	exit 1
}

#desc:check command exist
function check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}

function chk_params()
{
    check_command parted

    if [ -z "${DISK_NAME}" ]; then
        print_usage
    fi
    
    if [ ! -b "${DISK_NAME}" ]; then
        print_log "ERROR" "${DISK_NAME} is not a block device."
        print_usage
    fi 
    return 0
}


function disk_is_used()
{
    mount | grep "^/dev/" | awk '{print $1}' | grep "${DISK_NAME}" > /dev/null
    if [ $? -eq 0 ]; then
        print_log "ERROR" "${DISK_NAME} is used by mount."
        return 1
    fi
    
    df -P -h | grep "^/dev" | awk '{print $1}' | grep "${DISK_NAME}" > /dev/null
    if [ $? -eq 0 ]; then
        print_log "ERROR" "${DISK_NAME} is used by df."
        return 1
    fi
    
    swapon -s | grep "^/dev" | awk '{print $1}' | grep "${DISK_NAME}" > /dev/null
    if [ $? -eq 0 ]; then
        print_log "ERROR" "${DISK_NAME} is used by swap."
        return 1
    fi
    
    ps -wwef | grep -E "\ mkfs\.|\/mkfs\." | grep "${DISK_NAME}" > /dev/null
    if [ $? -eq 0 ]; then
        print_log "ERROR" "${DISK_NAME} is used by mkfs."
        return 1
    fi
    return 0
}

function disk_used_by_lvm()
{
    check_command blkid
    blk_info=$(blkid | grep "${DISK_NAME}" | awk '{print $1}' | awk -F ":" '{print $1}')
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

function clear_lvm_info()
{
    check_command pvs
    check_command vgs
    check_command lvdisplay
    check_command pvdisplay
    check_command lvremove
    check_command pvremove
    check_command vgremove
    pvs | grep "${DISK_NAME}[[:space:]]\+" > /dev/null
    if [ $? -eq 0 ]; then
        vg_name=$(pvdisplay "$DISK_NAME" | grep "VG Name"|awk '{print $NF}' | grep -v "Name")
        if [[ -n $vg_name ]]; then
          pv_num=$(vgs | grep "$vg_name" | awk '{print $2}')
          lv_num=$(vgs | grep "$vg_name" | awk '{print $3}')
          if [[ $lv_num -gt 1 ]]; then
            print_log "ERROR" "Nok, find $lv_num lv using $vg_name."
            exit 1
          fi

          if [[ $pv_num -gt 1 ]]; then
            print_log "ERROR" "Nok, find $pv_num pv in $vg_name."
            exit 1
          fi
          lv_name=$(lvdisplay "$vg_name" | grep "LV Name" | awk '{print $NF}' | grep -v "Name")
          if [[ -n $lv_name ]]; then
            # remove lv
            lvremove -y -q "/dev/$vg_name/$lv_name" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                print_log "ERROR" "Nok, lvremove /dev/$vg_name/$lv_name failed."
                exit 1
            fi
          fi
          # remove vg
          vgremove -y -q "$vg_name" >/dev/null 2>&1
          if [ $? -ne 0 ]; then
              print_log "ERROR" "Nok, vgremove $vg_name failed."
              return 1
          fi
        fi
        # remove pv
        pvremove -y -q "${DISK_NAME}" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_log "ERROR" "pvremove ${DISK_NAME} failed."
            return 1
        fi
    fi
    return 0
}

function clear_disk()
{
    disk_used_by_lvm
    if [[  $? -eq 1 ]]; then
      print_log "INFO" "${DISK_NAME} is used by lvm."
      clear_lvm_info
      if [ $? -ne 0 ]; then
          print_log "ERROR" "clear lvm info for ${DISK_NAME} failed."
          return 1
      fi
    fi
    parted -s ${DISK_NAME} mklabel msdos
    if [ $? -ne 0 ]; then
        print_log "ERROR" "parted -s ${DISK_NAME} mklabel msdos failed."
        return 1
    fi

    sleep 1
    
    partprobe ${DISK_NAME}
    if [ $? -ne 0 ]; then
        print_log "ERROR" "partprobe ${DISK_NAME} failed."
        return 1
    fi
    
    sleep 1
    
    dd if=/dev/zero of=${DISK_NAME} count=10 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_log "ERROR" "dd if=/dev/zero of=${DISK_NAME} count=10 failed."
        return 1
    fi

    return 0
}


function main()
{
    chk_params
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    disk_is_used
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    clear_disk
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    print_log "INFO" "clear ${DISK_NAME} successfully."
    return 0
}

main "$@"