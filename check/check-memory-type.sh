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

if [ $# -lt 1 ]; then
    print_log "ERROR" "Exactly one parameter is required."
    print_log "INFO" "Usage:$baseName <memory_type>  eg DDR2 , DDR3, DDR4, RAM"
    print_log "INFO" "Eg:$baseName DDR2"
    exit 1
fi

check_memtype() {
    local input_memtype=$(echo "$1" | tr '[A-Z]' '[a-z]')
    if which dmidecode > /dev/null 2>&1;then
        cur_memtype=$(dmidecode -t memory | head -45 | tail -23|grep Type|egrep -i "ddr|ram"|head -1|awk '{print $2}'| tr '[A-Z]' '[a-z]')
        if [ "${cur_memtype}" = "${input_memtype}" ];then
            print_log "INFO" "Ok.";return 0
        fi
        print_log "ERROR" "Nok.";return 1
    fi
	print_log "ERROR" "command <dmidecode> not exist"
	return 1
}

##### main#####
check_memtype "$1"
