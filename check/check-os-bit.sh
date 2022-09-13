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
baseName=$(basename "$0")


# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <os_bit>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 64"

}

function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

# desc: check os bit
# input: os_bit
# output: 1/0
function check_os_bit()
{
    check_input "$@"
    os_bit_flag=$1


    # os bit
    os_bit=$(getconf LONG_BIT)
    print_log "INFO" "Check OS bit"
    print_log "INFO" "Current: ${os_bit}, required: ${os_bit_flag}"
    if [[ ${os_bit} -eq ${os_bit_flag} ]] ; then
        print_log "INFO" "Ok"
        return 0
    else
        print_log "ERROR" "Nok"
        return 1
    fi
}


check_os_bit "$@"
