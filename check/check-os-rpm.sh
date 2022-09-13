#!/bin/bash

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=`basename $0`

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <rpm_list> | <rpm_list_file>"
    print_log "INFO" "Example:"
    print_log "INFO" "  $baseName unzip"
    print_log "INFO" "  $baseName vsftpd unzip yum"
    print_log "INFO" "  $baseName /tmp/$USER/rpm.list"
}

# desc: check if rpm list has installed
# input: rpm-version
# output: 1/0
function check_os_rpm()
{
    rpm_list_file=$1
    if [ $# -lt 1 ]; then
        print_log "ERROR" "At least one parameter is required."
        print_usage
        return 1
    fi

    # input as string
    local check_flag=0
    if [ ! -f $rpm_list_file ]; then

        for line in "$@"; do
            #Exclude lines that do not start with a letter or number
            if [ -z "$(echo "$line" | grep "^[[:alnum:]]")" ]; then
                continue
            fi
            #check rpm list
            version=$(rpm -q "$line")
            if [  $? -ne 0 ]; then
                print_log "ERROR" "$line is not installed"
                check_flag=$(($check_flag+1))
                #echo $check_flag
            else
                # ver=$(echo $version |cut -f2 -d '-')
                print_log "INFO" "$version is installed"
            fi
        done


    # input as a file
    else
        # define check_flag
        while read line || [[ -n ${line} ]]; do
            #Exclude lines that do not start with a letter or number
            if [ -z "$(echo "$line" | grep "^[[:alnum:]]")" ]; then
                continue
            fi
            #check rpm list
            version=$(rpm -q "$line")
            if [  $? -ne 0 ]; then
                print_log "ERROR" "$line is not installed"
                check_flag=$(($check_flag+1))
                #echo $check_flag
            else
                # ver=$(echo $version |cut -f2 -d '-')
                print_log "INFO" "$version is installed"
            fi
        done < "$rpm_list_file"


    fi

    [ $check_flag -ne 0 ] && print_log "ERROR" "At least one rpm in the list is not installed: nok." && return 1
    print_log "INFO" "All rpms in the list installed: ok."
    return 0
}
function check_os_dpkg()
{
    rpm_list_file=$1
    if [ $# -lt 1 ]; then
        print_log "ERROR" "At least one parameter is required."
        print_usage
        return 1
    fi

    # input as string
    local check_flag=0
    if [ ! -f $rpm_list_file ]; then
        for line in "$@"; do
            #Exclude lines that do not start with a letter or number
            if [ -z "$(echo "$line" | grep "^[[:alnum:]]")" ]; then
                continue
            fi
            #check rpm list
            version=$(dpkg -l |awk '{print $2, $3}'|grep "$line")
            if [  $? -ne 0 ]; then
                print_log "ERROR" "$line is not installed"
                check_flag=$(($check_flag+1))
                #echo $check_flag
            else
                # ver=$(echo $version |cut -f2 -d '-')
                print_log "INFO" "$version is installed"
            fi
        done

    # input as a file
    else
        # define check_flag
        while read line || [[ -n ${line} ]]; do
            #Exclude lines that do not start with a letter or number
            if [ -z "$(echo "$line" | grep "^[[:alnum:]]")" ]; then
                continue
            fi
            #check rpm list
            version=$(dpkg -l |awk '{print $2, $3}'|grep "$line")
            if [  $? -ne 0 ]; then
                print_log "ERROR" "$line is not installed"
                check_flag=$(($check_flag+1))
                #echo $check_flag
            else
                # ver=$(echo $version |cut -f2 -d '-')
                print_log "INFO" "$version is installed"
            fi
        done < "$rpm_list_file"
    fi
}

os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
if [ "$os_version" == "uos" ] ;then
    check_os_dpkg $@
else
    check_os_rpm $@
fi
