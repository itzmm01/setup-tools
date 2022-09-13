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
    print_log "INFO" "Usage: $baseName <java-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 2.7"

}

# desc: check java version
# input: java-version
# output: 1/0
function check_java_version()
{
    java_version_flag=$1
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    java_version_flag=$1
    # java-version
    if which java >/dev/null 2>&1; then
        java_version=$(java -version 2>&1|sed -n '1p'|awk -F '"' '{print $2}')
        #compare input and java version
        retcode=$(awk -v  ver1=$java_version_flag -v ver2=$java_version  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        if [ "$retcode" == "0" ]; then
            print_log "INFO" "check java version Ok"
            return 0
        else
            print_log "ERROR" "check java version Nok"
            return 1
        fi
    else
        print_log "ERROR" "java not installed"
        return 1
    fi

}


check_java_version $*
