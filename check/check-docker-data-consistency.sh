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
    print_log "INFO" "Usage: $baseName  <parameters> "
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName  192.168.1.1"
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
		check_command docker
		check_command kubectl
		ns_pod_list=$(kubectl get pods  -o wide -A | grep "$node_ip" |awk 'NR!=1{print $1","$2}')
		if [[ -n $ns_pod_list ]];then
			for ns_pod in $ns_pod_list; do
				ns=$(echo "$ns_pod" | awk -F"," '{print $1}')
				pod_name=$(echo "$ns_pod" | awk -F"," '{print $2}')
				docker_container_list=($(docker ps | grep "$pod_name" | grep -iv "pause" | awk '{print $1}'))
				if [[ -n $docker_container_list ]]; then
					for docker_container_id in ${docker_container_list[@]}; do
						docker_file_ResolvConfPath=$(docker inspect ${docker_container_id}  |grep   ResolvConfPath | awk -F"[ \":]+" '{print $3}')
						docker_file_HostnamePath=$(docker inspect ${docker_container_id}  |grep   HostnamePath | awk -F"[ \":]+" '{print $3}')
						docker_file_HostsPath=$(docker inspect ${docker_container_id}  |grep   HostsPath | awk -F"[ \":]+" '{print $3}')
						docker_file_LogPath=$(docker inspect ${docker_container_id}  |grep   LogPath | awk -F"[ \":]+" '{print $3}')
						if [[  -f $docker_file_ResolvConfPath && -f $docker_file_HostnamePath && -f $docker_file_HostsPath && $docker_file_LogPath ]];then
							print_log "$INFO" "CHECK DOCKER FILE OK"
						else
							print_log "$ERROR" "CHECK DOCKER FILE Nok"
							return 1
						fi
  					done
				fi
			done
		fi
}
		
########################
#     main program     #
########################
main  "$@"
