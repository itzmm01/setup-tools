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
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <service_name>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName service_name"
        print_log "INFO" "  $baseName service_name1 service_name2 service_name3"
        exit 1
    fi
}

# input: none
# output: 1/0
function check_service()
{
    service_name=$1
	print_log "INFO" "Check service status"
    ! systemctl list-unit-files |grep "$service_name.service" >/dev/null && print_log "INFO" "Ok. set $service_name service: off" && return 0
	service_status=$(systemctl status $service_name|grep inactive)
	if [ "$service_status" == "" ];then
		print_log "ERROR" "Nok. $service_name service status is not disabled."
		return 1
	else
		print_log "INFO" "Ok. $service_name service status is disabled."
	fi
}

function main()
{
    check_input "$@"
    for service_name in "$@"; do
        check_service "${service_name}"
    done
}
########################
#     main program     #
########################
main $@