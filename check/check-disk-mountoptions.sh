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

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path > <disk_mntOpts>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName /data defaults,rw"
    print_log "INFO" "  $baseName /data noatime,acl,user_xattr"

}

# check input
function check_input()
{
    if [ $# -lt 2 ]; then
        print_log "ERROR" "Exactly 2 argumnets are required"
        print_usage
        exit 1
    fi
}

# desc: check  hardware disk num
# input: path disk_mntOpts
# output: 1/0
function main(){

    check_input "$@"

    path=$1
    mntOpts=$2
    mntOptsArray=(${mntOpts//,/ })
    if [ ! -d "${path}" ]; then
        print_log "ERROR" "Path ${path} does not exist. Nok"
        return 1
    fi
    
    # get mount point of path
    mntPt=$(df "${path}" | tail -n 1 | awk '{print $6}')
    
    # get mount options of mount point
    realMntOptions=$(mount | grep  "${mntPt}[[:space:]]\+" | awk '{print $6}' | sed 's/(//g' | sed 's/)//g') 
    realMntOptionsArray=(${realMntOptions//,/ })
    
    print_log "INFO" "Current: ${realMntOptions} , Required: ${mntOpts}"

    # check each required mount options
    for mntOpt in "${mntOptsArray[@]}" ; do
        # sorry, defaults option is not supprted yet
        if [ "${mntOpt}" == "defaults" ] ; then
            print_log "WARN" "Ignore mount option \"${mntOpt}\""
            # ignore
            continue
        fi
        
        isFound=0
        # check if it is in current mount options
        for realMntOpt in "${realMntOptionsArray[@]}" ; do
            if [ "${mntOpt}" == "${realMntOpt}" ] ; then 
                isFound=1
                break
            fi
        done
        
        # is it found?
        if [ "${isFound}" == "0" ]; then
            print_log "ERROR" "Required mount option \"${mntOpt}\" cannot be found. Nok"
            return 1
        fi
    done
    
    print_log "INFO" "All required mount options are found. Ok"
}


########################
#     main program     #
########################
main "$@"
