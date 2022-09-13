#!/bin/bash
workdir=$(cd $(dirname "${BASH_SOURCE[0]}") && cd .. && pwd)
LOG_SAVE_PATH=./
TIMESTAMP=`date +"%Y%m%d%H%m%S"`

function print_log()
{
    log_level=$1
    log_msg=$2
    current_time=`echo $(date +%F%n%T)`
    echo "$current_time    [$log_level]    $log_msg"
}

log_path=${workdir}/log
COMMON_PARAM="-g LOG_JOB_PATH=${log_path}/job.log -g LOG_SCHEDULER_PATH=${log_path}/scheduler.log"
[ ! -d ${log_path} ] && mkdir -p ${log_path}

function get_config() {
    ini_file=$1
    section=$2
    item=$3
    value=`awk -F '=' '/['$section']/{a=1}a==1&&$1~/'$item'/{print $2;exit}' $ini_file`
    echo ${value}
}

function log()
{
    while getopts ":L:H:s:r:h:" opt; do
        case $opt in
            L)
                LOG_CONFIG_FILE=$OPTARG
                ;;
            H)
                HOST_CONFIG_FILE=$OPTARG
                ;;
            s)
                service_name=$OPTARG
                ;;
            r)
                role_name=$OPTARG
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

    if [ -z "${service_name}" ]; then
        print_log "INFO" "service name is not exist."
        return 1
    fi

    if [ -z "${LOG_CONFIG_FILE}" ] || [ ! -f "${LOG_CONFIG_FILE}" ]; then
        print_log "ERROR" "log config file is not exist."
        return 1
    fi

    if [ -z "${role_name}" ]; then
        collect_log_path=$(get_config ${LOG_CONFIG_FILE} ${service_name} ${service_name}.path)
        log_file_format=$(get_config ${LOG_CONFIG_FILE} ${service_name} ${service_name}.logfileformat)
    else
        collect_log_path=$(get_config ${LOG_CONFIG_FILE} ${service_name} ${service_name}.${role_name}.path)
        log_file_format=$(get_config ${LOG_CONFIG_FILE} ${service_name} ${service_name}.${role_name}.logfileformat)
    fi

    if [ -z "${HOST_CONFIG_FILE}" ] || [ ! -f "${HOST_CONFIG_FILE}" ]; then
        print_log "ERROR" "host config file is not exist."
        return 1
    fi

    filename="\${IP}_${service_name}_${TIMESTAMP}.tar.gz"
    tar_command="tar -zcf /tmp/$filename ${collect_log_path}/${log_file_format}"
    clean_command="rm -rf /tmp/$filename"

    if [ ! -z "$host" ]; then
       host_param="-sh $host"
    fi

    python ${workdir}/scheduler/scheduler.py -pr y -i ${HOST_CONFIG_FILE} -sc "$tar_command" $host_param $COMMON_PARAM > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        python ${workdir}/scheduler/scheduler.py -pr y -i ${HOST_CONFIG_FILE} $host_param -dp "${LOG_SAVE_PATH}" -sf "/tmp/$filename" -sm "in" $COMMON_PARAM > /dev/null 2>&1
        python ${workdir}/scheduler/scheduler.py -pr y -i ${HOST_CONFIG_FILE} $host_param -sc "$clean_command" $COMMON_PARAM > /dev/null 2>&1
    else
        print_log "ERROR" "Log zip failed."
    fi

    cd ${LOG_SAVE_PATH}
    ls *_${service_name}_${TIMESTAMP}.tar.gz > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        tar -zcf ${LOG_SAVE_PATH}/${service_name}_${TIMESTAMP}.tar.gz *_${service_name}_${TIMESTAMP}.tar.gz
        rm -rf ${LOG_SAVE_PATH}/*_${service_name}_${TIMESTAMP}.tar.gz
        print_log "INFO" "The logs save to current directory successful"
    else
        print_log "ERROR" "Log collect failed."
    fi
}

log "$@"