#!/bin/bash
workdir=$(cd $(dirname "${BASH_SOURCE[0]}") && cd .. && pwd)
LOG_CONFIG_FILE=${workdir}/conf/service-log.ini

function usage() {
    echo ""
    echo "Usage: cli logcollect -s servicename [-r rolename] [-L logconfig] [-h ip/hosts]"
    echo ""
    echo "Options:"
    echo "    -s        The service name that needs to collect logs"
    echo "    -r        The role name that needs to collect logs"
    echo "    -L        The log config file, default is ${workdir}/conf/service-log.ini"
    echo "    -h        The host where the log to be collected"
    echo ""
    echo "Sample:"
    echo "    cli logcollect -s hdfs"
    echo "    cli logcollect -s hdfs -r datanode -h 192.168.X.X"
}

[[ $1 = "--help" ]] && usage && exit 1

function logcollect()
{
    while getopts ":s:L:" opt; do
        case $opt in
            s)
                service_name=$OPTARG
                ;;
            L)
                LOG_CONFIG_FILE=$OPTARG
                ;;
            :)
                echo "Option -$OPTARG requires an argument."
                exit 1
                ;;
            ?)
                ;;
        esac
    done

    if [ -z "${service_name}" ]; then
        usage
        return 1
    fi
    bash ${workdir}/logcollect/log-collect.sh -L ${LOG_CONFIG_FILE} -H ${HOST_CONFIG_PATH} $@
}
