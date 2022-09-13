#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-cpu-arch.sh
# Description: a script to check if cpu arch on current machine
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
baseName=$(basename $0)

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <cpu_arch>"
    print_log "INFO" "  cpu_arch: logical cpu arch , e.g. x86_64"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName x86_64"

}


check_input()
{
    if [ $# != 1 ]; then
    #输入的参数等于1个
        print_log "ERROR" "Exactly one argument is required."
        print_usage
        exit 1
    fi
}

#desc: print cpu arch Is the expectation met
#input: cpu arch
#ouput: 0/1
check_cpu_arch(){
    check_input $@
    input_cpu_arch=$1
    input_cpu_arch_trans=$(echo $1 |tr 'A-Z' 'a-z'|tr '-' '_')
    local_cpu_arch=$(arch)
    if [ $local_cpu_arch == $input_cpu_arch_trans ] ;then 
         print_log "INFO" "Ok,Current: $local_cpu_arch."
    else
         print_log "ERROR" "Nok,Current: $local_cpu_arch."
         return 1 
    fi
}

check_cpu_arch $@
