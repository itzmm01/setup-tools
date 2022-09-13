#!/bin/bash

# $ nvcc -V

# below is the result
# nvcc: NVIDIA (R) Cuda compiler driver
# Copyright (c) 2005-2017 NVIDIA Corporation
# Built on Fri_Nov__3_21:07:56_CDT_2017
# Cuda compilation tools, release 9.1, V9.1.85


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
    print_log "INFO" "Usage: $baseName <cuda-version>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName 4.8.2"

}

# desc: check cuda version
# input: cuda-version
# output: 1/0
function check_cuda_version()
{
    cuda_version_flag=$1
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    cuda_version_flag=$1
    # cuda-version
    if which nvcc >/dev/null 2>&1; then
        cuda_version=$(nvcc -V 2>&1|grep release|awk -F '[ V]+' '{print $6}')
        #compare input and cuda version
        retcode=$(awk -v  ver1=$cuda_version_flag -v ver2=$cuda_version  'BEGIN{print(ver2>=ver1)?"0":"1"}')
        if [ "$retcode" == "0" ]; then
            print_log "INFO" "check cuda version Ok"
            return 0
        else
            print_log "ERROR" "check cuda version Nok"
            return 1
        fi
    else
        print_log "ERROR" "cuda not installed"
        return 1
    fi

}


check_cuda_version $*
