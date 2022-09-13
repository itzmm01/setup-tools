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
  res=$(kubectl get pvc -A --no-headers|awk '{if($3 != "Bound") print $1,$2,$3}')
  if [ "$res" != "" ]; then
    print_log "ERROR" "$res"
    exit 1
  fi

}

########################
#     main program     #
########################

main "$@"
