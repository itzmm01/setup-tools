#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-root.sh
# Description: a script to check if user is root
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
baseName=$(basename $0)

# desc: check if current user is root
# input: none
# output: 1/0
function check_current_user()
{
	print_log "INFO" "Check current user"
	user_id=$(id -u)
	if [ $user_id -eq 0 ];then
		print_log "INFO" "Ok current user is root"
        return 0
	else
		print_log "ERROR" "Nok current user is not root"
		return 1
	fi
}

########################
#     main program     #
########################
check_current_user