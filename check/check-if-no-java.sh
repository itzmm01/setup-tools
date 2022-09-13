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
    print_log "INFO" "Usage: $baseName"
    print_log "INFO" "Function: check if no java is installed on current host. 0 is returned if no java is installed, otherwise 1 is returned."
}

# desc: check python version
# input: python-version
# output: 1/0
function check_if_no_java()
{
    if command -v java --version >/dev/null ; then
        javaVersion=$(java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}')
        print_log "ERROR" "Java is already installed with version ${javaVersion}."
        return 1
    else
        print_log "INFO" "OK Java command no in system env."
    fi

}


check_if_no_java "$@"