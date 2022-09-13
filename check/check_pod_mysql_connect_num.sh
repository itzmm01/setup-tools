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

if [ $# -ne 5 ]; then
    print_log "ERROR" "Parameter error"
    print_log "INFO" "usage:$baseName <namespace> <si_name> <username> <password> <threshold>"
    print_log "INFO" "eg:$baseName sso mariadb-db-1 root 123456 0.8"
    exit 1
fi

function check_connect() {
    namespace="$1"
    si_name="$2"
    mysql_user="$3"
    mysql_pass="$4"
    threshold="$5"
    pod_list=($(kubectl -n ${namespace} get pod | grep ${si_name} | awk '{print $1}'))
    num=0
    for i in ${pod_list[@]}; do
        kubectl_str="kubectl exec -i -n ${namespace} $i -c agent -- mysql -u $mysql_user -p$mysql_pass"
        max_conn=$($kubectl_str -e"show variables like 'max_connections'" | grep max_connections | awk '{print $NF}')
        cur_conn=$($kubectl_str -e"show status like '%threads_conn%';" | grep Threads_connected | awk '{print $NF}')
        print_log "INFO" "$i max_conn-cur_conn: $max_conn-$cur_conn"
        if [ $(echo "scale=2;$cur_conn / $max_conn > $threshold" | bc) -eq 1 ]; then
            print_log "ERROR" "$i mysql connection too high max_conn-cur_conn: $max_conn-$cur_conn"
            let num++
        fi
    done
}

function main() {
    #        si_name: "mariadb"
    #        namespace: "sso"
    #        mysql_user: "root"
    #        mysql_pass: "123456"
    #        threshold: 0.8
    check_connect "$@"
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
