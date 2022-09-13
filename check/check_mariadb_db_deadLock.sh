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
    print_log "INFO" "usage:$baseName <si_name> <acquiring total order isolation num>"
    print_log "INFO" "eg:$baseName mariadb-db-1 5"
    exit 1
fi

function check_deadLock() {
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
                current=$(kubectl exec -i -n sso $pod -c xenon -- mysql -e "select count(1) as data from information_schema.processlist where state like '%acquiring total order isolation%' \G;" | grep data | awk '{print $2}')
                if [ $current -gt $threshold ]; then
                    print_log "ERROR" "${pod} 当前接收到的acquiring total order isolation=${current},会引发死锁，需要业务调整sql，短期重启pod可以恢复"
                    let num++
                fi
                print_log "INFO" "${pod} 不存在死锁"
            done
        else
            print_log "INFO" "${mariadb} 不是主从模式，跳过检查"
        fi
    done
}

function main() {
    check_deadLock "$@"
    if [ $error_num -ne 0 ]; then
        exit 1
    else
#        print_log "INFO" "不存在死锁"
        exit 0
    fi
}

main "$@"
