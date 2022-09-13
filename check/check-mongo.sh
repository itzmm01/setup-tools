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

if [ $# -lt 4 ]; then
    #输入的参数少于4个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "usage:$baseName <ip> <port> <username> <password>"
    print_log "INFO" "eg:$baseName 10.0.X.X 27017 <username> <password>"
    exit 1
fi

# check client command
function check_basic_command() {
    basic_command_flag=$1

    if which $basic_command_flag >/dev/null 2>&1; then
        mongo=$(which $basic_command_flag)
        print_log "INFO" "mongo client is ok， $mongo"
    else
        print_log "ERROR" "can not find mongo client"
        exit 1
    fi
}

# Check the connect status of internet
function check_ip_status() {
    ping -c 3 -i 0.2 -W 3 $1 &>/dev/null
    if [ $? -eq 0 ]; then
        print_log "INFO" "ping $1 is ok"
        return 0
    else
        print_log "ERROR" "cannot connect mongo server:$1"
        exit 1
    fi
}

function check_mongo() {

    mongo_ip=$1
    mongo_port=$2
    mongo_user=$3
    mongo_pass=$4
    exec_js=/tmp/$USER/readwritemongo.js

    nowtime=$(date +%s)

    cat <<EOF >${exec_js}

use setup_tools_check_${nowtime};

insert_data = {"host" : "${mongo_ip}", time:new Date()};
// del
db.check_table.remove({ "host" : "${mongo_ip}"});
// add
db.check_table.insert(insert_data);
// query
db.check_table.find({ "host" : "${mongo_ip}"});
// update
new_insert = {"host" : "${mongo_ip}", time:new Date()};
db.check_table.update(insert_data, new_insert);
// clean db
db.dropDatabase()
EOF

    get_cluster_shell="var a = rs.status(); a.members.forEach(function(e){print(e.name, e.stateStr)})"

    cluster_info=$($mongo --host $mongo_ip --port $mongo_port -u $mongo_user -p $mongo_pass --authenticationDatabase=admin --eval "$get_cluster_shell" --quiet 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        print_log "ERROR" "mongo node $1 is not ok! check server status or password"
        exit 1
    else
        role=$($mongo --host $mongo_ip --port $mongo_port -u $mongo_user -p $mongo_pass --authenticationDatabase=admin --eval "$get_cluster_shell" --quiet 2>/dev/null | grep $mongo_ip | awk '{print $2}')
        if [[ ${role} == 'SECONDARY' ]]; then
            print_log "INFO" "mongo node is ok! the node role is SECONDARY"
        elif [[ ${role} == 'PRIMARY' ]]; then
            print_log "INFO" "mongo node is ok! the node role is PRIMARY"
            $mongo --host $mongo_ip --port $mongo_port -u $mongo_user -p $mongo_pass --authenticationDatabase=admin --quiet <$exec_js | grep 'Error' -q 2>&1 >>/dev/null

            if [[ $? -ne 0 ]]; then
                print_log "INFO" "mongo node read and write is ok!"
            else
                exit 1
                print_log "ERROR" "mongo node $1 is not primary! check server status or password"
            fi
        else
            print_log "INFO" "Can't find node role,maybe it isn't cluster"
            $mongo --host $mongo_ip --port $mongo_port -u $mongo_user -p $mongo_pass --authenticationDatabase=admin --quiet <$exec_js | grep 'Error' -q 2>&1 >>/dev/null

            if [[ $? -ne 0 ]]; then
                print_log "INFO" "mongo node read and write is ok!"
            else
                exit 1
                print_log "ERROR" "mongo node $1 is not primary! check server status or password"
            fi
        fi
        print_log "INFO" "about cluster status:"
        echo "$cluster_info"
        rm -f $exec_js
        return 0
    fi

}

function main() {
    check_ip_status $1

    check_basic_command mongo

    check_mongo "$@"
}

########################
#     main program     #
########################

main "$@"
