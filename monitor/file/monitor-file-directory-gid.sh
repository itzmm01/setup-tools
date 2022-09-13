#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: monitor-file-direct-gid.sh
# Description: a script to monitor file directory gid
################################################################
# name of script
baseName=$(basename $0)
#desc: print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc；print how to use
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName  /data"
}
#dsec: check input
function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

# get file direct gid
file_persionmiss()
{
  check_input "$@"
  file=$1
  gid=""
  if [ ! -d "$1" ];then
    print_log "ERROR" "file directory:$1 not exist."
    exit 1
  else
    pdirect=$(echo ${file%/*})
    direct=$(echo ${file##*/})
    if [ ! $direct ];then
        print_log "ERROR" "file directory:/ not support."
        exit 1
    fi
    if [ ! $pdirect ] ;then
        pdirect="/"    
    fi 
    gid=$(ls -l $pdirect |grep "$direct" |awk '{print $4}')
    echo "$gid"
  fi  

}

file_persionmiss "$@"
