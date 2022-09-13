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
    echo "Usage: cli sendfile -s srcfile -d destfile [-h ip/hosts]"
    echo ""
    echo "Options:"
    echo "    -s        The source file to be distributed"
    echo "    -d        The destination file for distribution"
    echo "    -h        The host where the file to be distributed"
    echo ""
    echo "Sample:"
    echo "    cli sendfile -s cli.env -d /tmp"
    echo "    cli sendfile -s cli.env -d /tmp -h 192.168.X.X"
    echo ""
}

[[ $1 = "--help" ]] && usage && exit 1

log_path=${workdir}/log
COMMON_PARAM="-g LOG_JOB_PATH=${log_path}/job.log -g LOG_SCHEDULER_PATH=${log_path}/scheduler.log"
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function sendfile()
{
    while getopts ":s:d:h:" opt; do
        case $opt in
            s)
                srcfile=$OPTARG
                ;;
            d)
                destfile=$OPTARG
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

    if [ -z "$srcfile" ] || [ -z "$destfile" ]; then
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
    python ${workdir}/scheduler/scheduler.py -i ${HOST_CONFIG_PATH} -sf "$srcfile" -dp "$destfile" $host_param $COMMON_PARAM
}
