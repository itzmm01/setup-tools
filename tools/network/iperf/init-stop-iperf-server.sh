#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-stop-iperf-server.sh
# Description: a script to stop iperf3 server
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log() {
  log_level=$1
  log_msg=$2
  currentTime=$(echo $(date +%F%n%T))
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
stop_iperf() {
  check_input $@
  port=$1
  iperf_pid=$(ps -ef | grep iperf3 | grep "\-p $port \-D$" | grep -v "grep" | awk '{print $2}')
  if [[ -z $iperf_pid ]]; then
    print_log "INFO" "no iperf3 server running on port $port"
    return 0
  fi
  if kill -9 "$iperf_pid"; then
    print_log "INFO" "kill iperf3 ok, port is $port"
    return 0
  fi
  print_log "ERROR" "kill iperf3 failed, port is $port"
  return 1
}

########################
#     main program     #
########################
stop_iperf $@
