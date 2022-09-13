#!/bin/bash

# print log functions
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

function main() {
  host_ip="$(ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")"
  host_list=($(kubectl get node --no-headers | awk '{print $1}'|grep "$host_ip"))
  num=0
  for i in $host_list; do
    res=($(kubectl get node "$i" -o go-template --template='{{.status.capacity.cpu}} {{.status.capacity.memory}}'))
    cpu=$(grep -c processor /proc/cpuinfo)
    mem="$(free -k | awk 'NR==2{print$2}')Ki"
    if [ "${res[0]}" != "$cpu" ]; then
      print_log "ERROR" "get node cpu fail"
      let num++
    fi
    if [ "${res[1]}" != "$mem" ]; then
      print_log "ERROR" "get node mem fail"
      let num++
    fi
  done
  if [ $num -ne 0 ]; then
    exit 1
  else
    exit 0
  fi
}

########################
#     main program     #
########################

main "$@"
