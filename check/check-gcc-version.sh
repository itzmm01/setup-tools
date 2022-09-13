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
function print_usage()
{
    print_log "INFO" "Usage: $baseName <gcc-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 4.8.2"

}

# desc: check gcc version
# input: gcc-version
# output: 1/0
function check_gcc_version()
{
    gcc_version_flag=$1
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    gcc_version_flag=$1
    # gcc-version
    if which gcc >/dev/null 2>&1; then
        gcc_version=$(gcc --version 2>&1|sed -n '1p'|awk '{print $3}')
        #compare input and gcc version
        retcode=$(awk -v  ver1=$gcc_version_flag -v ver2=$gcc_version  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        if [ "$retcode" == "0" ]; then
            print_log "INFO" "check gcc version Ok"
            return 0
        else
            print_log "ERROR" "check gcc version Nok"
            return 1
        fi
    else
        print_log "ERROR" "gcc not installed"
        return 1
    fi

}


check_gcc_version $*
