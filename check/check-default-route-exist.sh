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
function check_route()
{
	print_log "INFO" "Check default route"
	route_gateway=$(route -n|awk '{print $1}'|grep "^0.0.0.0$")
	if [ "$route_gateway" == "" ];then
		print_log "ERROR" "Nok current default route is not exits"
        return 1
	else
        print_log "INFO" "Ok current default route  is exits"
        return 0
	fi
}

########################
#     main program     #
########################
check_route "$@"