#!/bin/bash

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
baseName=$(basename $0)

# desc: print how to use
function print_usage(){
    print_log "INFO" "Usage: $baseName <dev_name>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName /dev/vdb"
}

# desc: check if disk is rawdev
# input: dev_name
# output: 1/0
function check_disk_israwdev(){
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
    dev_name_flag=$1
    # fdisk 查看是否存在
    if ! fdisk -l 2>/dev/null|grep $dev_name_flag >/dev/null 2>&1; then
        print_log "ERROR" "$dev_name_flag not found"
        return 1
    fi
    # blkid 查看是否分区
    if $(echo $(blkid) |grep $dev_name_flag >/dev/null 2>&1); then
        print_log "ERROR" "$dev_name_flag is not rawdisk NOk"
        return 1
    fi
    # df查看是否挂载
    if ! df |grep $dev_name_flag >/dev/null 2>&1; then
        print_log "INFO" "$dev_name_flag is rawdisk Ok"
        return 0
    fi
    print_log "ERROR" "$dev_name_flag is not rawdisk NOk"
    return 1
}

########################
#     main program     #
########################
check_disk_israwdev $*
