#!/bin/bash
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}
# name of script
baseName=$(basename "$0")

if [ $# -ne 0 ]; then
    print_log "ERROR" "Parameter error"
    print_log "INFO" "usage:$baseName"
    print_log "INFO" "eg:$baseName"
    exit 1
fi

function main() {
    yesterday=$(date "+%Y-%m-%d" --date '1 days ago')
    today=$(date "+%Y-%m-%d")
    yesterday_mon=$(date "+%Y-%m-%d" --date '1 days ago' | awk -F '-' '{print $2}')
    today_mon=$(date "+%Y-%m-%d" | awk -F '-' '{print $2}')
    if [ $yesterday_mon != $today_mon ]; then
        yesterday=$today
    fi

    for podName in $(kubectl get pod -n kube-system | awk '/etcd/{ print $1 }'); do
        kubectl logs -n kube-system ${podName} >/tmp/$USER/${podName}.log
        count=0
        clock_result=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "clock difference against" | head -1 | awk '{print $1,$2}')
        network_local=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "local node might have slow network" | head -1 | awk '{print $1,$2}')
        network_buff=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "sending buffer is full" | head -1 | awk '{print $1,$2}')
        wal=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "sync duration of" | head -1 | awk '{print $1,$2}')
        heartbeat=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "failed to send out heartbeat on time" | head -1 | awk '{print $1,$2}')
        db_size=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "database space execeded" | head -1 | awk '{print $1,$2}')
        read_only=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "read-only range request" | head -1 | awk '{print $1,$2}')
        leader_change=$(awk "/${yesterday}/,/${today}/" /tmp/$USER/${podName}.log | grep -i "leader change" | head -1 | awk '{print $1,$2}')


        if [[ -n $clock_result ]]; then
            let count++
            print_log "ERROR" "${clock_result},${podName}出现Etcd 成员节点时钟不一致"
        fi
        if [[ -n $network_local ]]; then
            let count++
            print_log "ERROR" "${network_local},${podName}所在节点的网络速度可能较慢"
        fi
        if [[ -n $network_buff ]]; then
            let count++
            print_log "ERROR" "${network_buff},${podName}所在节点网络缓存区已满"
        fi
        if [[ -n $wal ]]; then
            let count++
            print_log "ERROR" "${wal},wal 日志持久化超时,${podName}所在节点磁盘io性能可能存在问题"
        fi
        if [[ -n $heartbeat ]]; then
            let count++
            print_log "ERROR" "${heartbeat}发送心跳报文超时,${podName}所在节点磁盘、CPU、网络性能不足都会导致该问题,一般为磁盘性能问题导致"
        fi
        if [[ -n $db_size ]]; then
            let count++
            print_log "ERROR" "${db_size},${podName}超出数据库空间"
        fi
        if [[ -n $read_only ]]; then
            let count++
            print_log "ERROR" "${read_only}etcd只读,${podName}所在节点磁盘io性能可能存在问题"
        fi
        if [[ -n $leader_change ]]; then
            let count++
            print_log "ERROR" "${leader_change}etcd切主,${podName}所在节点磁盘io性能可能存在问题"
        fi
        rm -f /tmp/$USER/${podName}.log
    done

    if [ $count -ne 0 ]; then
        exit 1
    else
        print_log "INFO" "etcd正常"
        exit 0
    fi
}

main
