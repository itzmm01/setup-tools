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
baseName=$(basename $0)

# desc: print how to use
function check_input()
{
    if [ $# -ne 2 ]; then
        print_log "INFO" "Usage: $baseName <ssh_config_item> <value>"
        print_log "INFO" "Example:"
        print_log "INFO" "$baseName Port 36000"
        exit 1
    fi
}
# input: none
# output: 1/0
function set_ssh_config()
{
   hv_Usedns=`cat /etc/ssh/sshd_config | grep -E "^\<UseDNS\>.*" | wc -l`
   if [[ $hv_Usedns -eq 1 ]];then
	sed -i 's/^\<UseDNS\>.*/#&/' /etc/ssh/sshd_config
    [[ -n "$(tail -c1 /etc/ssh/sshd_config )" ]] && echo >>/etc/ssh/sshd_config
	echo "UseDNS no" >> /etc/ssh/sshd_config &&\
        print_log "INFO" "Ok set ssh config UseDNS no" && return 0
        print_log "ERROR" "Nok set ssh config UseDNS no: failed"
        return 1
   else
        [[ -n "$(tail -c1 /etc/ssh/sshd_config )" ]] && echo >>/etc/ssh/sshd_config
        echo "UseDNS no" >> /etc/ssh/sshd_config &&\
        print_log "INFO" "Ok set ssh config UseDNS no" && return 0
        print_log "ERROR" "Nok set ssh config UseDNS no: failed"
        return 1
   fi
}

########################
#     main program     #
########################
set_ssh_config
