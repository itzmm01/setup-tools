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
  if [ $# -lt 1 ]
  then
      print_log "ERROR" "Missing argument"
      print_log "INFO" "Usage:$baseName 80"
      exit 1
  fi
  disk_info="$(df -hl -P | grep -E '/dev' | grep -v 'tmpfs\|/mnt'|awk '{sub(/%/,"",$5); if (strtonum($5) > '"$1"'){ print $NF,$5 } }')"
  if [ "$disk_info" != "" ]; then
    disk_usage_info=$(echo $disk_info)
    print_log "ERROR"  "获取磁盘使用率过多 $disk_usage_info"
#    print_log "ERROR 获取磁盘使用率过多"  "$disk_info"
    exit 1
  else
    print_log "INFO" "获取磁盘使用率当前值处于合理阈值之内"
  fi
}

########################
#     main program     #
########################
main $@
