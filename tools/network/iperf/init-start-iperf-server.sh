#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-start-iperf-server.sh
# Description: a script to start iperf3 server
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
    print_log "INFO" "Usage: $baseName <port>"
    print_log "INFO" "e.g.: $baseName 8888"
}

#desc:check command exist
function check_command()
{
    if ! which "$1" > /dev/null 2>&1; then
       print_log "ERROR" "command $1 could not be found."
       exit 1
    fi
}

# desc: check input
function check_input(){
    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        exit 1
    fi
}

# desc: start iperf
# input: none
# output: none
start_iperf() {
    check_input $@
    check_command iperf3
    port=$1
    iperf3 -s -p $port -D
    if [[ $? -eq 0 ]];then
      print_log "INFO" "start iperf3 ok, port is $port"
      return 0
    fi
    print_log "ERROR" "start iperf3 failed, port is $port"
    return 1
}


########################
#     main program     #
########################
start_iperf $@
