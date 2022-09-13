#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-k8s-node-status.sh
# Description: a script to check  k8s node all ready
################################################################
# name of script
baseName=$(basename $0)
# INFO ERROR
INFO="\e[033;32mINFO\e[0m"
ERROR="\e[033;31mERROR\e[0m"
#desc:print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime="$(date '+%F %T')"
    echo -e  "$currentTime    [$log_level]    $log_msg"
}


#desc: desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}

print_usage() 
{
    print_log "INFO" "Usage: $baseName <script> <IP> ]"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName  IP"
}
#desc: check input
function check_input()
{
    if [ $# -lt 1 ]; then
        print_log "ERROR" "At least one argument is required."
        print_usage
        exit 1
    fi
}

# get k8s node status
main() {
		check_input "$@"
		node_ip=$1
		return_code=0
		check_command docker
		check_command kubectl
		ns_pod_list=$(kubectl get pods  -o wide -A | grep "$node_ip" |awk 'NR!=1{print $1","$2}')
		if [[ -n $ns_pod_list ]]; then
			for ns_pod in $ns_pod_list; do
				ns=$(echo "$ns_pod" | awk -F"," '{print $1}')
				pod_name=$(echo "$ns_pod" | awk -F"," '{print $2}')
				pod_container_num=$(kubectl  get pods ${pod_name} -n ${ns} | awk 'NR !=1 {print $2}' | awk -F '/' '{print $2}')
				docker_contailner_num=$(docker ps  | grep  ${pod_name} | grep -v pause | wc -l)
				if [ "$pod_container_num" -eq  "$docker_contailner_num" ];then
					#print_log "$INFO" "OK"
					continue
				else
					print_log  "$ERROR" "Pod:${pod_name}@${ns} is Nok"
					return_code=1
				fi
			done
		fi
		return $return_code
}

########################
#     main program     #
########################
main "$@"
