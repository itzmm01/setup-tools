#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-disk-mntOpts.sh
# Description: a script to check  hardware disk mntOpts
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


function main(){
    fstab_info=($(cat /etc/fstab | grep -E '^/dev/' | grep -v 'swap' | awk '{print $1","$2}'))
    num=0
    for i in ${fstab_info[@]}; do
      mount_info=($(echo "$i"|awk -F ',' '{print $1,$2}'))
      res=$(df -Th|grep ''"${mount_info[0]}"''|awk '{print $NF}')
      if [ "$res" == "${mount_info[1]}" ]; then
        print_log "INFO" "所有分区/etc/fstab配置正常"
      else
        print_log "ERROR" "${mount_info} 分区没有配置/etc/fstab: $res"
        # shellcheck disable=SC2219
        let num++
      fi
    done
  if [ $num -ne 0 ]; then
    exit 1
  else
    exit 0
  fi
}

########################
#     main program     #
########################
main
