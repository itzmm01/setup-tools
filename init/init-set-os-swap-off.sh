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

# input: none
# output: 1/0
function set_os_swap_off()
{
	print_log "INFO" "set os swap: off"
	swap_status=$(free -h |grep -i Swap|awk '{print $2}')
	check_swap_mount=$(cat /etc/fstab | grep swap)
	if [ "$swap_status" == "0B" ];then
		if [ "${check_swap_mount:0:1}" == "#" -o "$check_swap_mount" == "" ];then
		    print_log "INFO" "Ok os swap: off"
            return 0
		else
			sed -i '/swap/ s/^/#/g'  /etc/fstab && print_log "INFO" "Ok os swap: off" && return 0
            print_log "ERROR" "Nok set os swap off: failed"
			return 1
		fi
    else
		swapoff -a && sed -i '/swap/ s/^/#/g'  /etc/fstab && print_log "INFO" "Ok os swap: off" && return 0
		print_log "ERROR" "Nok set os swap off: failed"
        return 1
    fi
}

########################
#     main program     #
########################
set_os_swap_off