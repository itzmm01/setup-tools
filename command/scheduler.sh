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
    echo "Usage: cli scheduler -c jobconfig [-i hostconfig] [-p paramconfig] ..."
    echo ""
    echo "Options:"
    echo "    -c        The scheduler job to be executed"
    echo "    -i        The host info config"
    echo "    -p        The param info config"
    echo ""
    echo "Sample:"
    echo "    cli scheduler -c jobconfig.yml"
    echo "    cli scheduler -c jobconfig.yml -i hostconfig.yml -p paramconfig.yml"
    echo ""
}

[[ $1 = "--help" ]] && usage && exit 1

log_path=${workdir}/log
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function scheduler()
{
    while getopts ":c:" opt; do
        case $opt in
            c)
                jobconfig=$OPTARG
                ;;
            :)
                echo "Option -$OPTARG requires an argument."
                exit 1
                ;;
            ?)
                ;;
        esac
    done

    if [ -z "$jobconfig" ]; then
        usage
        return 1
    fi
    # execute scheduler command
    py_ver=$(python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
    if [[  $py_ver -ne 2 ]]; then
        print_log "ERROR" "python2.x is required."
        exit 1
    fi
    python ${workdir}/scheduler/scheduler.py -s y -i ${HOST_CONFIG_PATH} -g LOG_JOB_PATH=${log_path}/job.log -g LOG_SCHEDULER_PATH=${log_path}/scheduler.log "$@"
}
