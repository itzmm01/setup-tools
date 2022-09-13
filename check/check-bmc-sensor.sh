#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: check-bmc-sensor.sh
# Description: a script to check bmc sensor less than define value
################################################################

# name of script
baseName=$(basename $0)
print_usage() 
{
    print_log "INFO" "Usage: $baseName <model>"
    print_log "INFO" "Example:"
    print_log "INFO" "    $baseName 10.16.X.X root password ('CPU0_Temp' 'CUP1_Temp1')"
}
#desc:print log
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}
#desc:check input
function check_input()
{
    if [ $# -ne 5 ]; then
        print_log "ERROR" "Exactly five argument is required."
        print_usage
        exit 1
    fi
}
#desc:check command exist
function check_command()
{
    if ! [ -x "$(command -v $1)" ]; then
       print_log "ERROR" "$1 could not be found."
       exit 1
    fi
}



# get bmc sensor
bmc_sensor()
{
    check_command ipmitool
    check_input "$@"
    sensorList=$4
    isAllOk=0
    for sensor in ${sensorList[*]}; do
    temp=`ipmitool -I lanplus -H $1  -U  $2 -P  $3 sensor get $sensor|grep 'Sensor Reading'|awk '{print $4}'`
    temp_1=`echo $temp | cut -d \. -f 1`
        if [[ $temp_1 -gt $5 ]]; then
            print_log "ERROR" "Nok,$sensor:$temp_1"
            isAllOk=1
        else
            print_log "INFO" "Ok"
        fi
    done
    
    return ${isAllOk}

}

bmc_sensor"$@"

