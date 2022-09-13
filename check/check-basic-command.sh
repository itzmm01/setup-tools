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

# desc: print how to use
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName <basic-command>"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName command"
        print_log "INFO" "  $baseName command1 command2 command3"
        exit 1
    fi
}

# desc: check basic command
# output: 1/0
function check_basic_command()
{
    basic_command_flag=$1
    if which $basic_command_flag >/dev/null 2>&1; then
        print_log "INFO" "Ok"
    else
        print_log "ERROR" "$basic_command_flag not installed Nok"
        return 1
    fi

}

function main()
{
    check_input "$@"
    for basic_command_flag in "$@"; do
        check_basic_command "${basic_command_flag}"
    done
}

########################
#     main program     #
########################
main "$@"

