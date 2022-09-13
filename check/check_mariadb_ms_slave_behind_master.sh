#!/bin/bash
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")

if [ $# -ne 2 ]; then
    print_log "ERROR" "Parameter error"
    print_log "INFO" "usage:$baseName <threshold> <si_name>"
    print_log "INFO" "eg:$baseName 3000 mariadb-db-1"
    exit 1
fi

function check_salve_behind() {
    threshold=$1
    si_name=$2
    if [ $si_name = 'mariadb' ]; then
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | awk '{print $1}'))
    else
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | grep $si_name | awk '{print $1}'))
    fi
    error_num=0
    for mariadb in $(kubectl get mariadb -nsso | grep -v NAME | awk '{print $1}'); do
        mode=$(kubectl get mariadb $mariadb -nsso -oyaml | grep mode | awk -F ':' '{print $NF}' | sed -e 's/^[ \t]*//g')
        if [ "$mode" == "MS" ]; then
            for pod in $(kubectl -nsso get pods -lssm.infra.tce.io/role=slave | grep -v NAME | grep $mariadb | grep mariadb | awk '{print $1}'); do
                current=$(kubectl -nsso exec -i $pod -c xenon -- mysql -uroot -p123456 -e "show slave status \G;" | grep Seconds_Behind_Master | awk '{print $2}')
                if [ "$current" == "NULL" ]; then
                    print_log "ERROR" "${pod}主从延时失败,当前Seconds_Behind_Master = ${current}"
                    let error_num=error_num+1
                    continue
                fi
                if [ $current -ge $threshold ]; then
                    let error_num=error_num+1
                    print_log "ERROR" "${pod}主从延时超过${threshold}"
                    continue
                fi
                print_log "INFO" "${pod} Seconds_Behind_Master = ${current}"
            done
        else
            print_log "INFO" "${mariadb} 不是主从模式，跳过检查"
        fi
    done
}
function main() {
    check_salve_behind "$@"
    if [ $error_num -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"