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
    echo "Usage: cli cmd -c 'COMMAND' [-h ip/hosts]"
    echo ""
    echo "Options:"
    echo "    -c        The command to be executed"
    echo "    -h        The host where the command is executed"
    echo ""
    echo "Sample:"
    echo "    cli cmd -c 'ls -l /'"
    echo "    cli cmd -c 'ls -l /' -h 192.168.X.X"
    echo ""
}

[[ $1 = "--help" ]] && usage && exit 1

log_path=${workdir}/log
COMMON_PARAM="-g LOG_JOB_PATH=${log_path}/job.log -g LOG_SCHEDULER_PATH=${log_path}/scheduler.log"
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function cmd()
{
    while getopts ":c:h:" opt; do
        case $opt in
            c)
                cmd=$OPTARG
                ;;
            h)
                host=$OPTARG
                ;;
            :)
                echo "Option -$OPTARG requires an argument."
                exit 1
                ;;
            ?)
                echo "Invalid option: -$OPTARG"
                ;;
        esac
    done

    if [ -z "${HOST_CONFIG_PATH}" ] || [ ! -f "${HOST_CONFIG_PATH}" ]; then
        print_log "ERROR" "host config file is not exist."
        return 1
    fi

    if [ -z "$cmd" ]; then
        usage
        return 1
    fi

    if [ -z "$host" ]; then
       print_log "INFO" "execute command on all hosts."
    else
       host_param="-sh $host"
    fi

    py_ver=$(python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
    if [[  $py_ver -ne 2 ]]; then
        print_log "ERROR" "python2.x is required."
        exit 1
    fi

    python ${workdir}/scheduler/scheduler.py -pr y -i ${HOST_CONFIG_PATH} -sc "$cmd" $host_param $COMMON_PARAM
}
