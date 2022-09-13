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

function check_salve_io() {
    si_name=$1
    if [ $si_name = 'mariadb' ]; then
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | awk '{print $1}'))
    else
        mariadb_list=($(kubectl get mariadb -nsso | grep -v NAME | grep $si_name | awk '{print $1}'))
    fi
    error_num=0
    for mariadb in ${mariadb_list[@]}; do
        mode=$(kubectl get mariadb $mariadb -nsso -oyaml | grep mode | awk -F ':' '{print $NF}' | sed -e 's/^[ \t]*//g')
        if [ "$mode" == "MS" ]; then
            for pod in $(kubectl -nsso get pods -lssm.infra.tce.io/role=slave | grep -v NAME | grep $mariadb | grep mariadb | awk '{print $1}'); do
                current=$(kubectl -nsso exec -i $pod -c xenon -- mysql -uroot -p123456 -e "show slave status \G;" | grep Slave_IO_Running | grep No | wc -l)
                if [ $current -eq 1 ]; then
                    let error_num=error_num+1
                    print_log "ERROR" "${mariadb} ${pod}集群Slave_IO_Running 状态异常"
                else
                    print_log "INFO" "${mariadb} ${pod}集群Slave_IO_Running 状态正常"
                fi
            done
        else
            print_log "INFO" "${mariadb} 不是主从模式，跳过检查"
        fi
    done
}

function main() {
    check_salve_io "$@"
    if [ $error_num -eq 0 ]; then
        print_log "INFO" "所有主从模式下的mariadb集群Slave_IO_Running 状态正常"
        exit 0
    else
        print_log "ERROR" "至少有1个主从模式下的mariadb集群Slave_IO_Running 状态异常，请进行检查分析"
        exit 1
    fi
}

main "$@"
