#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-python-version.sh
# Description: a script to check if cpu core on current machine
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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

function is_decimal()
{
    str=$1

    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        return 1
    fi

    print_log "INFO" "Check if $str is a valid decimal number."

    if [[ $str =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "ERROR" "Nok."
        return 1
    fi
}


# name of script
baseName=$(basename "$0")



# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <python-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 2.7"
}

function check_input()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi
}

# input: python-version, operator
# output: 1/0
function check_python_version()
{

    check_input "$@"
    python_version=$1
    if ! is_decimal "${python_version}" >/dev/null 2>&1; then
        print_log "ERROR" "Input \"$python_version\" is not valid. Only is_decimal is allowed."
        print_usage
        return 1
    fi
    print_log "INFO" "Check if python is installed with required version"
    pybin=$(which python 2>/dev/null || which python2 2>/dev/null || which python3 2>/dev/null)
    if [[ -x $pybin ]]; then
        # check if python-version is valid
        # is it an decimal ?
        # get python version on current machine
        py_ver="$($pybin -V 2>/dev/null | awk '{print $2}' | awk -F'.' '{print $1"."$2}')"
        print_log "INFO" "Current: ${py_ver}, required: ${python_version}"

        if [ "$py_ver" == "$python_version" ]; then
            print_log "INFO" "Ok"
            return 0
        fi
        print_log "ERROR" "Nok"
        return 1
    fi
    print_log "ERROR" "Python command is not found in system env"
    return 1
}


########################
#     main program     #
########################
check_python_version "$@"
