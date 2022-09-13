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

if [ $# -lt 2 ]; then
    #输入的参数少于2个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port> [username] [password]"
    print_log "INFO" "eg:$baseName 10.0.X.X 9200 [username] [password]"
    exit 1
fi

# Check the connect status of internet
check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &>/dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
        return 0
    fi
    return 1
}

check_es() {

    es_host=$1
    es_port=$2
    es_user=$3
    es_pass=$4

    code=""
    nowtime=$(date +%s)

    # check health yellow or green
    curl -s -u $es_user:$es_pass "$es_host:$es_port/_cluster/health?pretty&wait_for_status=yellow&timeout=120s" &>/dev/null
    code=$(expr $code + $?)

    # add index
    curl -s -m 5 -X PUT -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-$nowtime" &>/dev/null
    code=$(expr $code + $?)
    # curl -s -m 5 -u $es_user:$es_pass "$es_host:$es_port/_cat/indices" | grep -q "setup-tools-check-${nowtime}"

    # add doc
    curl -s -m 5 -H "Content-Type: application/json" -X POST -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-${nowtime}/_doc/$HOSTNAME?pretty" -d '
{
    "data": "'$nowtime'",
    "hostname": "'$HOSTNAME'"
}' &>/dev/null
    code=$(expr $code + $?)

    #query
    getdate=$(curl -s -m 5 -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-${nowtime}/_doc/$HOSTNAME?pretty" | grep data | awk -F\" '{print $4}')
    [[ $getdate -eq $nowtime ]]
    code=$(expr $code + $?)

    # update
    newtime=$(date +%s)
    curl -s -m 5 -H "Content-Type: application/json" -X POST -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-${nowtime}/_doc/$HOSTNAME?pretty" -d '
{
    "data": "'$newtime'",
    "hostname": "'$HOSTNAME'"
}' &>/dev/null
    code=$(expr $code + $?)

    #query new data
    getdate=$(curl -s -m 5 -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-${nowtime}/_doc/$HOSTNAME?pretty" | grep data | awk -F\" '{print $4}')
    [[ $getdate -eq $newtime ]]
    code=$(expr $code + $?)

    # clean index
    curl -s -m 5 -X DELETE -u $es_user:$es_pass "$es_host:$es_port/setup-tools-check-${nowtime}" &>/dev/null
    code=$(expr $code + $?)

    if [[ $code -ne 0 ]]; then
        print_log "ERROR" "es node $1 is not ok! check server status or password"
        exit 1
    else
        print_log "INFO" "es node read and write is ok!"
        cluster_info=$(curl -s -m 5 -u $es_user:$es_pass "$es_host:$es_port/_cluster/health?pretty" | sed -n '2,6p')
        nodes=$(curl -s -m 5 -u $es_user:$es_pass "$es_host:$es_port/_cat/nodes")
        print_log "INFO" "about cluster status:"
        echo "$cluster_info"
        echo "${nodes}"
        return 0
    fi

}

check_ip_status $1
if [ $? -ne 0 ]; then
    print_log "ERROR" "cannot connect es server:$1"
    exit 1
fi

########################
#     main program     #
########################

check_es "$@"
