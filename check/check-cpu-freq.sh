#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-cpu-freq.sh
# Description: a script to check if cpu freq on current machine
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
baseName=$(basename "$0")


# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <cpu_freq>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 2.60GHz"

}

# desc: check if cpu freq is ok
# input: cpu_freq
# output: 1/0
function check_cpu_freq()
{

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    cpu_freq_flag=$1
    if ! echo "$cpu_freq_flag"|grep -i Ghz >/dev/null 2>&1;then
        print_log "ERROR" "parameter is not ok ,need GHz"
        print_usage
        return 1
    fi
    cpu_freq_flag=$(echo $1 |tr 'a-z' 'A-Z')
    cpu_freq_flag=${cpu_freq_flag%G*}
    cpu_freq_flag=$(echo "$cpu_freq_flag*1000"|bc)
    print_log "INFO" "Check if cpu freq is ok."
    # check if cpu_freq is valid
    # get  cpu freq on current machine
    cpu_freq=$(lscpu|grep "CPU MHz" | awk '{print $3}')
    retcode=$(awk -v  ver1="$cpu_freq_flag" -v ver2="$cpu_freq"  'BEGIN{print(ver2>=ver1)?"0":"1"}')
    print_log "INFO" "Current: $cpu_freq_flag, required: $cpu_freq."
    if [ "$retcode" == "0" ]
    then
        print_log "INFO" "check cpu freq  Ok"
        return 0
    else
        print_log "ERROR" "check cpu freq Nok"
        return 1
    fi
}


########################
#     main program     #
########################
check_cpu_freq "$@"
