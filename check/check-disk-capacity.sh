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
baseName=`basename $0`

if [ $# -lt 2 ]
then
#输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "Usage:$baseName <path><capacity>"
    print_log "INFO" "Eg:$baseName /data/test 500G"
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

check_disk_capacity()
{
    path=$1
    capacity=$2
    print_log "INFO" "Check if capacity of path $path is ok"
    root_cap=$(df -m|grep -w "/" |awk '{print $2}')
    #在df中匹配输入的路径
    real_cap=$(df -m |awk -v dp=$path '{if($6 == dp)print $2}' )
    while [ -z $real_cap ] && [ ! -z $path ]
    do
    #若输入的路径是分区的子目录，则依次往上去匹配。比如挂载的分区是/data，输入的目录是/data/test/test2,则会从/data/test/test2,/data/test,/data,/，依次匹配
        path=$(echo ${path%/*})
        real_cap=$(df -m |awk -v dp=$path '{if($6 == dp)print $2}' )
    done
    if [ ! -z $real_cap ]
    then
        #在df中匹配到了分区,对分区容量进行比较
        print_log "INFO" "Compare path is $path."
        disk_capacity_compare $real_cap $capacity
        exit $?
    else
        #在df中未匹配到分区,则默认用/分区比较
        print_log "INFO" "Compare path is /."
        real_cap=$root_cap
        disk_capacity_compare $real_cap $capacity
        exit $?
    fi
}

disk_capacity_compare()
{
    real_cap=$1
    capacity=$2
    MB=$(echo "$capacity"|grep -E -i "m$|mb$"|awk -F'm|M' '{print $1}')
    GB=$(echo "$capacity"|grep -E -i "g$|gb$"|awk -F'g|G' '{print $1}')
    TB=$(echo "$capacity"|grep -E -i "t$|tb$"|awk -F't|T' '{print $1}')
    if [ ! -z $MB ];then
        compare_cap=$(echo $MB)
        compare_cap $real_cap  $compare_cap
	compare_cap_return=$?
        log_real_cap=$real_cap
        print_log "INFO" "Current: ${log_real_cap}M, required: ${capacity}"
        #return $?
        return ${compare_cap_return}
    elif [ ! -z $GB ];then
        #输入的数值是GB单位,转换为MB再进行比较
        compare_cap=$(echo $[GB*1000])
        compare_cap $real_cap  $compare_cap
	compare_cap_return=$?
	#echo ${compare_cap_return}
        log_real_cap=$(echo $[real_cap/1000])
	#return $? 
        print_log "INFO" "Current: ${log_real_cap}G, required: ${capacity}"
        #return $? 
        return ${compare_cap_return}
    elif [ ! -z $TB ];then
        #输入的数值是TB单位,转换为MB再进行比较
        compare_cap=$(echo $[TB*1000*1000])
        compare_cap $real_cap  $compare_cap
	compare_cap_return=$?
	#echo ${compare_cap_return}
        log_real_cap=$(echo $[real_cap/1000000])
        #$(echo "scale=2; $real_cap/1000000"|bc)
        print_log "INFO" "Current: ${log_real_cap}T, required: ${capacity}"
        #return $?
        return ${compare_cap_return}
    else
        #输入的数值未带单位,则默认为MB
        compare_cap=$capacity
        compare_cap $real_cap  $compare_cap
	compare_cap_return=$?
        print_log "INFO" "Current: ${real_cap}M, required: ${capacity}M"
        #return $?
        return ${compare_cap_return}
    fi
}

compare_cap_return=0
compare_cap()
{
    real_cap=$1
    compare_cap=$2
    if [ $real_cap -ge $compare_cap  ]
    then
        #实际挂载的分区容量比输入的分区容量大,满足分区要求
        print_log "INFO" "Ok."
        return 0
    else
        #实际挂载的分区容量比输入的分区容量小,不满足分区要求
        print_log "WARNING" "Nok."
        return 1
    fi
}

check_disk_capacity $1 $2
