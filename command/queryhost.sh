#!/bin/bash
workdir=$(cd $(dirname "${BASH_SOURCE[0]}") && cd .. && pwd)

function print_log()
{
    log_level=$1
    log_msg=$2
    current_time=`echo $(date +%F%n%T)`
    echo "$current_time    [$log_level]    $log_msg"
}

function usage() {
    echo ""
    echo "Usage: cli queryhost -h host-group"
    echo ""
    echo "Options:"
    echo "    -h        Optional, The host group you want to query. query all groups as default"
    echo "    -i        Optional, The host config file. HOST_CONFIG_PATH exported in cli.env as default"
    echo ""
    echo "Sample:"
    echo "    cli queryhost"
    echo "    cli queryhost -h dns-server"
    echo "    cli queryhost -h dns-server -i config/hosts.yml"
    echo ""
}

[[ $1 = "--help" ]] && usage && exit 1

log_path=${workdir}/log
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function queryhost()
{
    hostconfig=${HOST_CONFIG_PATH}
    while getopts ":h:i:" opt; do
        case $opt in
            h)
                groupconfig=$OPTARG
                ;;
            i)
                hostconfig=$OPTARG
                ;;
            :)
                echo "Option -$OPTARG requires an argument."
                exit 1
                ;;
            ?)
                ;;
        esac
    done

    if [ -z "${hostconfig}" ] || [ ! -f "${hostconfig}" ]; then
        print_log "ERROR" "host config file is not exist."
        return 1
    fi

    # execute query command
    py_ver=$(python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
    if [[  $py_ver -ne 2 ]]; then
        print_log "ERROR" "python2.x is required."
        exit 1
    fi
    python ${workdir}/scheduler/scheduler.py -qi ${groupconfig} -i ${hostconfig}
}
