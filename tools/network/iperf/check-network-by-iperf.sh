#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-network-by-iperf.sh
# Description: a script to check network by iperf3
################################################################

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log() {
  log_level=$1
  log_msg=$2
  currentTime="$(date '+%F %T')"
  echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")
# desc: print how to use
function print_usage() {
  print_log "INFO" "Usage: $baseName <server_ip> <server_port> <protocol> <time> <bandwidth> <pkg_bytes> <indicator> <threshold> <operator> [ratio]"
  print_log "INFO" "Example:"
  print_log "INFO" "  $baseName 127.0.X.X 8888 UDP 10 100M 2048 loss 0.1 gt"
  print_log "INFO" "  $baseName 127.0.X.X 8888 TCP 10 100M 2048 loss 0.1 gt 1"
}
# desc: check input
function check_input() {
  if [ $# -lt 9 ]; then
    print_log "ERROR" "nine or ten parameters are required. found $#"
    print_usage
    exit 1
  fi
}
#desc:check command exist
function check_command() {
  if ! which "$1" >/dev/null 2>&1; then
    print_log "ERROR" "command $1 could not be found."
    exit 1
  fi
}

function convert() {
  input=$1
  if [ -z "${input//[0-9]/}" ]; then
   value=${input}
  else
    unit=${input#${input%?}}
    num=${input%${lastchar}}
    case $unit in
        m|M)
        value=$(awk -v x="$num" -v y=1 'BEGIN{printf "%d",x*y}')
        ;;
        g|G)
        value=$(awk -v x="$num" -v y=1000 'BEGIN{printf "%d",x*y}')
        ;;
        *)
        print_log "ERROR" "Only support m/M/g/G as unit."
        exit 1
        ;;
    esac
  fi
  echo "$value"
}

function compare() {
  num=$1
  num_compare=$2
  operator=$3
  if [[ "$operator" == "le" ]] && [[ -n "$num" ]] && [[ -n "$num_compare" ]]; then
    rc=$(awk -v ver1="$num" -v ver2="$num_compare" 'BEGIN{print(ver1<=ver2)?"0":"1"}')
    operatorSign="<="
  elif [[ "$operator" == "eq" ]] && [[ -n "$num" ]] && [[ -n "$num_compare" ]]; then
    rc=$([ "$num" == "$num_compare" ] && echo 0 || echo 1)
    operatorSign="="
  elif [[ "$operator" == "ge" ]] && [[ -n "$num" ]] && [[ -n "$num_compare" ]]; then
    rc=$(awk -v ver1="$num" -v ver2="$num_compare" 'BEGIN{print(ver1>=ver2)?"0":"1"}')
    operatorSign=">="
  elif [[ "$operator" == "gt" ]] && [[ -n "$num" ]] && [[ -n "$num_compare" ]]; then
    rc=$(awk -v ver1="$num" -v ver2="$num_compare" 'BEGIN{print(ver1>ver2)?"0":"1"}')
    operatorSign=">"
  elif [[ "$operator" == "lt" ]] && [[ -n "$num" ]] && [[ -n "$num_compare" ]]; then
    rc=$(awk -v ver1="$num" -v ver2="$num_compare" 'BEGIN{print(ver1<ver2)?"0":"1"}')
    operatorSign="<"
  else
    # Invalid operator or version
    print_log "ERROR" "Invalid input if operator or compare number"
    exit 1
  fi
  print_log "INFO" "Current: $num, required: $operatorSign$num_compare"
  return "$rc"
}

# desc: mount disk
# input: server_ip, server_port, protocol, time, bandwidth, pkg_bytes, indicator, threshold, operator, [ratio]
# output: 1/0
main() {
  #check
  check_input $@
  check_command iperf3
  check_command jq-linux64
  #set local var
  local server_ip="$1"
  local server_port="$2"
  local protocol="$3"
  local time="$4"
  local bandwidth="$5"
  local pkg_bytes="$6"
  local indicator="$7"
  local threshold
  threshold=$(convert "$8")
  local operator="$9"
  local ratio=1
  if [ $# -eq 10 ]; then
    tmp_ratio=$(awk -v x="${10}" -v y="100" 'BEGIN{printf "%.3f",x/y}')
    ratio=$(awk -v x=1 -v y="$tmp_ratio" 'BEGIN{printf "%.3f",x+y}')
  fi

  # TODO add some check for params
  if [[ $protocol == "UDP" ]]; then
    declare -A udp_dic
    udp_dic=([loss]=".end.sum.lost_percent" [delay]=".end.sum.jitter_ms" [upload_bandwidth]=".end.sum.bits_per_second" [download_bandwidth]=".end.sum.bits_per_second")
    json_key=${udp_dic[$indicator]}
    # not defined in udp_dic, will exit 1
    if [[ -z $json_key ]]; then
      print_log "ERROR" "unsupported indicator '$indicator'."
      return 1
    fi
    if [[ $indicator == "download_bandwidth" ]]; then
      result=$(iperf3 -c "$server_ip" -p "$server_port" -u -t "$time" -l "$pkg_bytes" -b "$bandwidth" -R -J)
    else
      result=$(iperf3 -c "$server_ip" -p "$server_port" -u -t "$time" -l "$pkg_bytes" -b "$bandwidth" -J)
    fi
    if [[ $? -eq 0 ]]; then
      indicator_result=$(echo "$result" | jq-linux64 "$json_key")
      if [[ $indicator == "download_bandwidth" ]] || [[ $indicator == "upload_bandwidth" ]]; then
        # convert unit from bps to MBps
        indicator_result=$(awk -v x="$indicator_result" -v y=1000 'BEGIN{printf "%.3f",x/y/y}')
      fi
      if [[ -n $indicator_result ]]; then
        indicator_compare=$(awk -v x="$threshold" -v y="$ratio" 'BEGIN{printf "%.3f",x*y}')
        if compare "$indicator_result" "$indicator_compare" "$operator"; then
          print_log "INFO" "check $indicator ok."
          return 0
        fi
        print_log "ERROR" "check $indicator failed."
        return 1
      fi
    fi
    print_log "ERROR" "run iperf client failed."
    return 1
  else
    declare -A tcp_dic
    tcp_dic=([upload_bandwidth]=".end.sum_sent.bits_per_second" [download_bandwidth]=".end.sum_received.bits_per_second")
    json_key=${tcp_dic[$indicator]}
    if [[ -z $json_key ]]; then
      print_log "ERROR" "unsupported indicator '$indicator'."
      return 1
    fi
    if [[ $indicator == "download_bandwidth" ]]; then
      result=$(iperf3 -c "$server_ip" -p "$server_port" -t "$time" -l "$pkg_bytes" -b "$bandwidth" -R -J)
    else
      result=$(iperf3 -c "$server_ip" -p "$server_port" -t "$time" -l "$pkg_bytes" -b "$bandwidth" -J)
    fi
    if [[ $? -eq 0 ]]; then
      indicator_result=$(echo "$result" | jq-linux64 "$json_key")
      if [[ -n $indicator_result ]]; then
        indicator_compare=$(awk -v x="$threshold" -v y="$ratio" 'BEGIN{printf "%.3f",x*y}')
        if compare "$indicator_result" "$indicator_compare" "$operator"; then
          print_log "INFO" "check $indicator ok."
          return 0
        fi
        print_log "ERROR" "check $indicator failed."
      fi
    fi
    return 1
  fi
}
########################
#     main program     #
########################
main $@
