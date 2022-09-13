#!/bin/bash
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")

if [ $# -ne 1 ]; then
    print_log "ERROR" "Parameter error"
    print_log "INFO" "usage:$baseName <si_name>"
    print_log "INFO" "eg:$baseName mariadb-db-1"
    exit 1
fi

function analyze_last_error() {
    si_name=$1
    if [ $si_name = 'mariadb' ]; then
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | awk '{print $1}'))
    else
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | grep $si_name | awk '{print $1}'))
    fi
    for mariadb in ${mariadb_list[@]}; do
        mode=$(kubectl get mariadb $mariadb -nsso -oyaml | grep mode | awk -F ':' '{print $NF}' | sed -e 's/^[ \t]*//g')
        if [ "$mode" == "MS" ]; then
            for pod in $(kubectl -nsso get pods -lssm.infra.tce.io/role=slave | grep -v NAME | grep $mariadb | grep mariadb | awk '{print $1}'); do
                current=$(kubectl -nsso exec -i $pod -c xenon -- mysql -uroot -p123456 -e "show slave status \G;" |grep Last_IO_Error| awk -F 'Last_IO_Error:' '{print $2}')
                if [ ! "$current" == ' ' ]; then
                  print_log "ERROR" "Last_IO_Error: ${mariadb} ${pod} ${current}"
                fi
            done
        fi
    done
}

function main() {
    analyze_last_error "$@"
}

main "$@"
