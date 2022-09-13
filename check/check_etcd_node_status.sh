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

if [ $# -lt 5 ]; then
    #输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <namespace> <filed> <field_expr> <value> <enable_ssl> <cacert> <cert> <key>"
    print_log "INFO" "eg:$baseName kube-system dbsize ge 2000 ssl /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/server.crt /etc/kubernetes/pki/etcd/server.key"
    exit 1
fi


function main() {
  ns="$1"
  field="$2"
  field_expr="$3"
  thresholds="$4"
  enable_ssl="$5"
  # /etc/kubernetes/pki/etcd/ca.crt
  if [ "$6" == "" ]; then
    cacert="/etc/kubernetes/pki/etcd/ca.crt"
  else
    cacert="$6"
  fi

  if [ "$7" == "" ]; then
    cert="/etc/kubernetes/pki/etcd/server.crt"
  else
    cert="$7"
  fi

  if [ "$8" == "" ]; then
    key="/etc/kubernetes/pki/etcd/server.key"
  else
    key="$8"
  fi

  host_list=($(kubectl get po -n $ns --no-headers | grep etcd | awk '{print $1}'))
  if [ "$enable_ssl" != "" ]; then
    etcd_opt="--endpoints=https://127.0.0.1:2379 --cacert=$cacert --cert=$cert --key=$key"
  else
    etcd_opt="--endpoints=https://127.0.0.1:2379 "
  fi
  num=0
  for i in $host_list; do
    cmd_str="ETCDCTL_API=3 etcdctl $etcd_opt  endpoint status --write-out=json"
    res=$(kubectl -n $ns exec -i $i -- sh -c "$cmd_str"|jq .[].Status.${field})
    # shellcheck disable=SC1072
    if [ "$res" -${field_expr} "$thresholds" ]; then
      print_log "INFO" "etcd 节点状态值检查成功"
    else
      print_log "ERROR" "etcd 节点 $i 状态不满足 ${field} ${field_expr} ${thresholds}"
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
