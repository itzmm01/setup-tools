#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-cpu-core.sh
# Description: a script to check if memory size on current
# machine meets requirement
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

function is_int()
{
    str=$1

    if [ "$str" == "" ]; then
        print_log "ERROR" "Input is empty."
        return 1
    fi

    print_log "INFO" "Check if $str is a valid positive integer."
    if [[ $str =~ ^[+-]?[0-9]+$  ]]; then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "ERROR" "Nok."
        return 1
    fi
}


function to_lower()
{
    str=`echo "$1" | tr '[A-Z]' '[a-z]'`
    echo $str
}


# name of script
baseName=`basename $0`

# desc: print how to use
function print_usage()
{
    #print_log "INFO" "Usage: $baseName {memory_size_unit} {operator}"
    print_log "INFO" "Usage: $baseName <memory_size_unit>"
    print_log "INFO" "  memory_size: memory size with unit, e.g. 8g. Available options for unit: g|G|m|M|k|K."
    #print_log "INFO" "  operator: operator when compare given cpu_core to current available cpu core, options: gt|ge|eq, default: ge"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 8g"
    print_log "INFO" "  $baseName 4096m"

}

# desc: check if memory size is ok
# input: memory_size, operator
# output: 1/0
function check_memory_size()
{
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    memory_size_unit=$1
    operator=$2
    result=1
    print_log "INFO" "Check if memory size is ok."

    # check if memory_size is valid
    # is it empty?
    if [ "$memory_size_unit" == "" ]; then
        print_log "ERROR" "Input parameter is empty."
        print_usage
        return 1
    else
        len=${#memory_size_unit}
        memory_size=${memory_size_unit:0:$len-1}
        unit=${memory_size_unit:0-1:1}
        # is it an valid integer number?

        case "$unit" in
            g|G|m|M|k|K)
                unit=$(to_lower $unit)
                ;;
            *)
                print_log "ERROR" "Unit $unit from input \"$memory_size_unit\" is not valid. Available unit: g|G|m|M|k|K."
                print_usage
                return 1
                ;;
        esac

        is_int "$memory_size" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_log "ERROR" "Memory size \"$memory_size\" from input \"$memory_size_unit\" is not valid. Only integer is allowed."
            print_usage
            return 1
        fi

    fi

    # get total memory on current machine
    totalMemorySize=`free --si -$unit | sed -n '2p' | awk '{print $2}'`

    print_log "INFO" "Current: $totalMemorySize$unit, required: $memory_size_unit."

    if [ $totalMemorySize -ge $memory_size ];then
        print_log "INFO" "Ok."
        return 0
    else
        print_log "WARNING" "Nok."
        return 1
    fi


}


########################
#     main program     #
########################
check_memory_size $*
