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
        print_log "INFO" "Usage: $baseName <modules_name>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName modules_name"
        print_log "INFO" "  $baseName modules_name1 modules_name2 modules_name3"
        exit 1
    fi
}
# input: none
# output: 1/0
function set_kernel_mod_load()
{
    check_input "$@"
    mod_name="$1"
	check_mod=$(modprobe "$mod_name")
	check_mod_load=$(cat /etc/modules-load.d/"$mod_name".conf | grep "$mod_name")
    print_log "INFO" "set $mod_name kernel mod load"
	if [ "$check_mod" == "" ];then
		if [ "$check_mod_load" == "" ];then
            echo "$mod_name" > /etc/modules-load.d/"$mod_name".conf &&\
            print_log "INFO" "Ok set $mod_name kernel mod: load." && return 0
            print_log "ERROR" "Nok set $mod_name kernel mod load: failed"
            return 1
		else
			print_log "INFO" "Ok set $mod_name kernel mod: load."
            return 0
		fi
    else
        modprobe "$mod_name" &&  echo "$mod_name" > /etc/modules-load.d/"$mod_name".conf &&\
        print_log "INFO" "Ok set $mod_name kernel mod: load." && return 0
        print_log "ERROR" "Nok set $mod_name kernel mod load: failed"
		return 1
    fi
}

########################
#     main program     #
########################
set_kernel_mod_load $@