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
    currentTime="$(date '+%F %T')"
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=`basename $0`
if [ $# -lt 1 ]
then
#输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "Usage:$baseName <path>"
    print_log "INFO" "Eg:$baseName /data"
    exit 1
else
    echo $1|grep -q "^/"
    retcode=$?
    if [ "$retcode" != "0" ]
    then
        print_log "ERROR" "Path $1 is not /xx beginning"
        exit 1
    fi
fi
#check_disk_capacity
check_disk_capacity()
{
    path=$1
    root_cap_used_utilization=$(df -m|grep -w "/" |awk '{print $5}'|awk -F % '{print $1}')
    #在df中匹配输入的路径
    real_cap_used_utilization=$(df -m |awk -v dp=$path '{if($6 == dp)print $5}'|awk -F % '{print $1}')
    while [ -z $real_cap_used_utilization ] && [ ! -z $path ]
    do
    #若输入的路径是分区的子目录，则依次往上去匹配。比如挂载的分区是/data，输入的目录是/data/test/test2,则会从/data/test/test2,/data/test,/data,/，依次匹配
        path=$(echo ${path%/*})
        real_cap_used_utilization=$(df -m |awk -v dp=$path '{if($6 == dp)print $5}'|awk -F % '{print $1}')
    done
    if [ -z $real_cap_used_utilization ];then
        #在df中未匹配到分区,则默认用/分区比较
        real_cap_used_utilization=$root_cap_used_utilization
    fi
    echo $real_cap_used_utilization
}
########################
#     main program     #
########################
check_disk_capacity $1
