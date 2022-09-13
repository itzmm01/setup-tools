#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-os-version.sh
# Description: a script to check if current os version on machine
# meet the given requirement
# meets requirement
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
baseName=`basename $0`

# desc: print how to use
function print_usage ()
{

    print_log "INFO" "Usage: $baseName <os-version> <operator>"
    print_log "INFO" "  <os-version>: required os type, e.g. 7.2/7.3"
    print_log "INFO" "  <operator>: supported: le/eq/ge"
    print_log "INFO" "e.g.: $baseName 7.2 ge"


}



# desc: check os version
# input: version, operator
# output: 1/0
function check_os_version()
{
    if [ $# -ne 2 ]; then
        print_log "ERROR" "Exactly 2 parameters are required"
        print_usage
        exit 1
    fi

    input_version=$1
    operator=$2

    # get current os version
    if which lsb_release >/dev/null 2>&1; then
        version=$(lsb_release -r|awk '{print $2}'|cut -d"." -f1-2)
    elif [ -f /etc/debian_version ]; then
        version=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        version=$(cat /etc/redhat-release |awk '{print $4}' |cut -d"." -f1-2)
    elif [ -f /etc/centos-release ]; then
        version=$(cat /etc/centos-release |awk '{print $4}' |cut -d"." -f1-2)
    elif [ -f /etc/SuSE-release ]; then
        version=$(cat /etc/SuSE-release  |grep VERSION  |awk -F'=' '{print $2}')
    elif [ -f /etc/kylin-release ]; then
        version=$(grep -Eo 'release .*[0-9]' /etc/kylin-release | awk '{print $NF}' | sed 's/[a-zA-Z]//g')
    else
        print_log "ERROR" "Unknow OS type"
        return 1
    fi

    # compare current version with required version
    if [ "$operator" == "le" -a ! -z "$version" ]; then
        rc=$(awk -v  ver1=$input_version -v ver2=$version  'BEGIN{print(ver2<=ver1)?"0":"1"}')
        operatorSign="<="
    elif [ "$operator" == "eq" -a ! -z "$version" ]; then
        rc=$( [ "$version" == "$input_version" ] && echo 0 || echo 1)
        operatorSign="="
    elif [ "$operator" == "ge" -a ! -z "$version" ]; then
        rc=$(awk -v  ver1=$input_version -v ver2=$version  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        operatorSign=">="
    else
        # Invalid operator or version
        print_log "ERROR" "Invalid input if operator or version"
        exit 1
    fi

    print_log "INFO" "Current: $version, required: $operatorSign$input_version"

    if [ "$rc" == "0" ]; then
            print_log "INFO" "Ok."
    else
        print_log "ERROR" "Nok."
    fi
    return ${rc}
}


check_os_version $*
