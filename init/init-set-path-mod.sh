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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <path> <mod>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName /tmp 777"

}
# input: none
# output: 1/0
function set_path_mod()
{
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly two parameter is required."
        print_usage
        return 1
    fi
    path_flag=$1
    mod_flag=$2
    print_log "INFO" "set $path_flag $mod_flag"
    chmod $mod_flag $path_flag && print_log "INFO" "Ok. set $path_flag $mod_flag" && return 0
    print_log "ERROR" "Nok. set $path_flag $mod_flag：failed"
}

########################
#     main program     #
########################
set_path_mod $@