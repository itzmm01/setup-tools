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

# desc: check kernel mod status
# output: 1/0
function check_mod_load()
{
	print_log "INFO" "Check kernel mod status"
    mod_name="$1"
	check_mod=$(lsmod |awk '{print $1}' |grep "^$mod_name$")
	if [ "$check_mod" == "" ];then
        print_log "ERROR" "Nok $mod_name mod is not load"
		return 1
    else
        print_log "INFO" "Ok $mod_name mod is load"
		return 0
    fi
}

function main()
{
    check_input "$@"
    for mod_name in "$@"; do
        check_mod_load "${mod_name}"
    done
}

########################
#     main program     #
########################
main "$@"