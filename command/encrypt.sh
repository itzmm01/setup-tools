#!/bin/bash
workdir=$(cd $(dirname "${BASH_SOURCE[0]}") && cd .. && pwd)

function print_log()
{
    log_level=$1
    log_msg=$2
    current_time=`echo $(date +%F%n%T)`
    echo "$current_time    [$log_level]    $log_msg"
}

log_path=${workdir}/log
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function encrypt()
{
    # execute scheduler command
    py_ver=$(python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
    if [[  $py_ver -ne 2 ]]; then
        print_log "ERROR" "python2.x is required."
        exit 1
    fi
    python ${workdir}/scheduler/scheduler.py -ep y  -i ${HOST_CONFIG_PATH} -g LOG_JOB_PATH=${log_path}/job.log -g LOG_SCHEDULER_PATH=${log_path}/scheduler.log -sc "echo encrypt ${HOST_CONFIG_PATH}" -sh "local"
}
