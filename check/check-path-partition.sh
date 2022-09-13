#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-network-name.sh
# Description: a script to check if the required path is mounted
# meets requirement
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
baseName=$(basename $0)


# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <DIR>"
    print_log "INFO" "check_path_partition:  dir"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName  /data"
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

#desc: print cpu arch Is the expectation met
#input: path
#ouput: 0/1
check_path_partition(){
    check_input $@
    path=$1
    print_log  "INFO"  "check check_path_partition"
	if [ ! -d "${path}" ] ; then
        print_log "ERROR" "Path ${path} does not exist"
        return 1
    fi
	if  which df >/dev/null 2>&1; then
		disk_base=`df  /  | awk -F ' ' '{print $1}' | sed '1,1d' 2>/dev/null`
		disk_path=`df  ${path}  | awk -F ' ' '{print $1}' | sed '1,1d' 2>/dev/null`
		#check disk_path is disk 
		fdisk -l ${disk_path} >/dev/null 2>&1  || { print_log "ERROR" "check_path_partition:this path is not disk"; return 1; }
		if [[ ${disk_base} != ${disk_path} ]]; then
            print_log "INFO" "check_path_partition:OK"  &&  return 0  
        fi
        print_log "ERROR" "check_path_partition:failed"  &&  return 1
	fi
	print_log "ERROR"  "check_path_partition: df tools not installd"  && return 1
}

check_path_partition $@
