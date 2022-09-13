#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-docker-pull-images.sh
# Description: a script to check pull images
################################################################
# name of script
baseName=$(basename $0)

# desc: print how to use
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc: pring log
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName registry.tce.com/library/flannel:v0.10.0"
}

# desc: check input
check_input()
{
    if [ $# -ne 1 ];then
        print_log "ERROR" "Exactly one arguments is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}


#desc: docker pull images
main()
{
    check_command docker
    check_input "$@"
    print_log "INFO" "Check docker pull image"
    pullInfo=`docker pull $1|grep Digest|wc -l`
    if [[ pullInfo -eq 1 ]];then
        print_log "INFO" "ok"
    else
        print_log "ERROR" "Nok,docker pull $1 failed"
        return 1;
    fi
}

main "$@"
