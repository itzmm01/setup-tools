#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-mount-disk.sh
# Description: a script to part disk
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log() {
  log_level=$1
  log_msg=$2
  currentTime="$(date +'%F %T')"
  echo "$currentTime    [$log_level]    $log_msg"
}

# desc: print how to use
function print_usage() {
  print_log "INFO" "Usage: $baseName <dev_name> <mnt_path> <mnt_fstype> <mnt_opt> <mnt_fstype_opt> [capacity]"
  print_log "INFO" "Example:"
  print_log "INFO" "  $baseName /dev/sdb /data1 xfs '' '-n ftype=1' 30G"
  print_log "INFO" "  $baseName /dev/sdb /data ext4 '' ''"
  print_log "INFO" "  $baseName /dev/sdb /data xfs '' '-n ftype=1' other"
  print_log "INFO" "unit support: MB,GB,TB"
  print_log "INFO" "GB is used by default."
}

# name of script
baseName=$(basename "$0")

function chk_params() {
  which parted >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    print_log "ERROR" "command <parted> not exist"
    return 1
  fi

  if [ -z "${dev_name}" ]; then
    print_usage
    return 1
  fi

  if [ ! -b "${dev_name}" ]; then
    print_log "ERROR" "${dev_name} is not a block device."
    print_usage
    return 1
  fi

  # whether already parted 4 partitions?
  part_num=$(lsblk -l "${dev_name}" | grep -c "part")
  if [[ $part_num -ge 4 ]]; then
    print_log "ERROR" "Nok, ${dev_name} cannot make more than 4 partitions."
    return 1
  fi

  local df_disk
  df_disk=$(df -P | grep "$part_mnt_path$" | awk '{print $1}' )
  if [[ -n $df_disk ]]; then
    print_log "ERROR" "Nok, ${part_mnt_path} already mounted by ${df_disk}."
    return 1
  fi

  local mount_disk
  mount_disk=$(mount | grep "${part_mnt_path}[[:space:]]\+" | awk '{print $1}')
  if [[ -n $mount_disk ]]; then
    print_log "ERROR" "Nok, ${part_mnt_path} already mounted by ${mount_disk}."
    return 1
  fi
  return 0
}

function mk_part_label() {
  # mklabel for disk
  parted -s "${dev_name}" mklabel gpt
  if [ $? -ne 0 ]; then
    print_log "ERROR" "parted -s ${dev_name} mklabel gpt failed."
    return 1
  fi
  sleep 1

  partprobe "${dev_name}"
  if [ $? -ne 0 ]; then
    print_log "ERROR" "partprobe ${dev_name} failed."
    return 1
  fi
  return 0
}

function get_cur_part() {
  before=$1
  current=$(lsblk -l "${dev_name}" | grep "part" | awk '{print $1}')
  for part in $current; do
    # find the part not in $before
    if [[ ! $before =~ $part ]]; then
      cur_part=$part
      break
    fi
  done

  if [[ -z $cur_part ]]; then
    print_log "ERROR" "Nok, find new part fail."
    return 1
  fi
  full_part_name=$(blkid | grep "$cur_part" | awk -F ":" '{print $1}')
  return 0
}

function convert_part_size() {
  MB=$(echo "$1"|grep -E -i "m$|mb$"|awk -F'm|M' '{print $1}')
  GB=$(echo "$1"|grep -E -i "g$|gb$"|awk -F'g|G' '{print $1}')
  TB=$(echo "$1"|grep -E -i "t$|tb$"|awk -F't|T' '{print $1}')
  if [[ -n $MB && $MB =~ ^[1-9][0-9]?$ ]];then
    tmp_size=$MB
  elif [[ -n $GB && $GB =~ ^[1-9][0-9]?$ ]]; then
    tmp_size=$((GB*1000))
  elif [[ -n $TB && $TB =~ ^[1-9][0-9]?$ ]]; then
    tmp_size=$((TB*1000*1000))
  else
    if [[ $1 =~ ^[1-9][0-9]?$ ]]; then
      tmp_size=$(($1*1000))
    fi
  fi

  if [[ -n $tmp_size ]]; then
    converted_part_size=$tmp_size
    return 0
  fi
  print_log "ERROR" "capacity param should be integer or integer with unit."
  return 1
}

# desc: part disk
# input: fs_type, dev_name, path, mount_option, fs_option
# output: 1/0
mount_part() {
  local fs_type="$1"
  local dev_name="$2"
  local mnt_path="$3"
  local mnt_opt="$4"
  local fs_opt="$5"
  [[ -n "$mnt_opt" ]] || mnt_opt="defaults,noatime,nodiratime"
  [[ -d "$mnt_path" ]] || mkdir "$mnt_path"
  if [[ $fs_type = xfs ]]; then
    mkfscmd="mkfs.xfs -f"
  elif [[ $fs_type = ext4 ]]; then
    mkfscmd="mkfs.ext4 -F"
  else
    print_log "ERROR" "fstype:$fs_type not supported yet."
    return 1
  fi

  if ! [[ -b $dev_name ]]; then
    print_log "ERROR" "$dev_name not a block device."
    return 1
  fi
  blktype=$(blkid "$dev_name" -s TYPE -o value)
  if ! [[ "$blktype" = "$fs_type" ]]; then
    $mkfscmd $fs_opt "$dev_name"
  fi
  if ! grep -wq "^$dev_name" /etc/fstab; then
    [[ -n "$(tail -c1 /etc/fstab)" ]] && echo >>/etc/fstab
    echo "$dev_name $mnt_path $fs_type $mnt_opt 0 0" >>/etc/fstab
  fi
  systemctl daemon-reload >/dev/null 2>&1
  mount -a
}

function main() {
  # check whether params count is ok
  if [[ $# -lt 5 || $# -gt 6 ]]; then
    print_log "ERROR" "number of params should be 5 or 6."
    print_usage
    return 1
  fi
  local dev_name="$1"
  local part_mnt_path="$2"
  chk_params
  if [ $? -ne 0 ]; then
    return 1
  fi
  # init the disk part info if necessary
  part_label=$(parted "${dev_name}" print 2>/dev/null | grep "^Partition Table" | awk '{print $3}')
  if [[ -z $part_label || $part_label == "unknown" ]]; then
    mk_part_label
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi

  part_mnt_fs_type=$3
  # only xfs or ext4 supported
  if [[ $part_mnt_fs_type != xfs ]] && [[ $part_mnt_fs_type != ext4 ]]; then
    print_log "ERROR" "fstype:$part_mnt_fs_type not supported yet."
    return 1
  fi

  part_mnt_opt=$4
  part_mnt_fs_opt=$5
  # convert part size to unit of MB
  if [[ -n $6 && $6 != "other" ]]; then
    convert_part_size "$6"
    if [[ $? -ne 0 ]]; then
      return 1
    fi
    part_size=$converted_part_size
    if [[ $part_size -lt 1 ]]; then
      print_log "ERROR" "Target partition capacity is too small."
      return 1
    fi
  fi

  before_part=$(lsblk -l "${dev_name}" | grep "part" | awk '{print $1}')
  part_begin_size_m=$(parted -s "${dev_name}" unit MB print | grep -v "^[[:space:]]*$" | sed -n '$p' | awk '{print $3}'  | tr -d '[:alpha:]')
  if [[ -z $part_begin_size_m ]]; then
    part_begin_size_m=0
  fi

  dev_max_size_m=$(parted -s "${dev_name}" unit MB print | grep "^Disk ${dev_name}:" | awk '{print $3}' | awk -F"." '{print $1}' | tr -d '[:alpha:]')

  if [[ $part_begin_size_m -ge $dev_max_size_m ]]; then
    print_log "ERROR" "Disk capacity has been fully parted."
    return 1
  fi

  part_end_size_m=$dev_max_size_m
  if [[ -n $part_size ]]; then
    part_end_size_m=$((part_begin_size_m + part_size))
    if [[ $part_end_size_m -gt $dev_max_size_m ]]; then
      print_log "ERROR" "Capacity not enough."
      return 1
    fi
  fi
  parted -s "${dev_name}" mkpart primary "$part_mnt_fs_type" "${part_begin_size_m}M" $part_end_size_m"M"
  if [ $? -ne 0 ]; then
    print_log "ERROR" "Make partition for ${dev_name} failed."
    return 1
  fi
  get_cur_part "${before_part}"
  if [ $? -ne 0 ]; then
    return 1
  fi
  print_log "INFO" "Make partition ${full_part_name} ok."
  # mount the part
  mount_part "$part_mnt_fs_type" "$full_part_name" "$part_mnt_path" "$part_mnt_opt" "$part_mnt_fs_opt"
  if [ $? -ne 0 ]; then
    print_log "ERROR" "Nok, mount ${full_part_name} to ${part_mnt_path} failed."
    return 1
  fi
  print_log "INFO" "Ok, init disk partition ${dev_name} ok."
  return 0
}

main "$@"
