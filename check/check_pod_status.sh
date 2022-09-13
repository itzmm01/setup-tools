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

if [ $# -lt 1 ]; then
    #输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <namespace>"
    print_log "INFO" "eg:$baseName sso (or all)"
    exit 1
fi


function main() {
     #   app_name, namespace="sso"
  namespace="$1"
  num=0
  if [ "$namespace" == "all" ]; then
      res=$(kubectl get pod -A --no-headers |grep -Pv 'Running|Completed|Succeeded'|awk  '{print $1,$2,$3,$4}')
      if [ "$res" != "" ]; then
        let num++
        print_log "ERROR" "$res"
      fi
      ready=$(kubectl get pod -A --no-headers |grep Running| awk -F '[ :]+|/' '{if ($3!=$4)print $1,$2,$3,$4}')
      if [ "$ready" != "" ]; then
        let num++
        print_log "ERROR" "$ready"
      fi
  else
      res=$(kubectl get pod -n $namespace --no-headers |grep -Pv 'Running|Completed|Succeeded'|awk  '{print "'"$namespace"'",$1,$2,$3}')
      if [ "$res" != "" ]; then
        let num++
        print_log "ERROR" "$res"
      fi
      ready=$(kubectl get pod -n $namespace --no-headers |grep Running| awk -F '[ :]+|/' '{if ($2!=$3)print "'"$namespace"'",$1,$2,$3}')
      if [ "$ready" != "" ]; then
        let num++
        print_log "ERROR" "$ready"
      fi
  fi
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
