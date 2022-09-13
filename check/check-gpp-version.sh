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
    print_log "INFO" "Usage: $baseName <g++-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 4.8.2"

}

# desc: check g++ version
# input: g++-version
# output: 1/0
function check_gpp_version()
{
    gpp_version_flag=$1
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    gpp_version_flag=$1
    # g++-version
    if which g++ >/dev/null 2>&1; then
        gpp_version=$(g++ --version 2>&1|sed -n '1p'|awk '{print $3}')
        #compare input and g++ version
        retcode=$(awk -v  ver1=$gpp_version_flag -v ver2=$gpp_version  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        if [ "$retcode" == "0" ]; then
            print_log "INFO" "check g++ version Ok"
            return 0
        else
            print_log "ERROR" "check g++ version Nok"
            return 1
        fi
    else
        print_log "ERROR" "g++ not installed"
        return 1
    fi

}


check_gpp_version $*
