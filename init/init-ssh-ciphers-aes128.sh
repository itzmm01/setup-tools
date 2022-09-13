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

# input: aes128-ctrne
# output: 1/0
function set_ciphers_aes128_config()
{
   hv_Ciphers=`cat /etc/ssh/sshd_config | grep -E "^\<Ciphers\>.*" | wc -l`
   [[ -n "$(tail -c1 /etc/ssh/sshd_config )" ]] && echo >>/etc/ssh/sshd_config
   if [[ $hv_Ciphers -eq 1 ]];then
        sed -i 's/^\<Ciphers\>.*/#&/' /etc/ssh/sshd_config
        echo "Ciphers aes128-ctr" >> /etc/ssh/sshd_config &&\
        print_log "INFO" "Ok set ssh config Ciphers aes128-ctr" && return 0
        print_log "ERROR" "Nok. aes128-ctr set ssh config Ciphers aes128-ctr: failed"
        return 1
   else
        echo "Ciphers aes128-ctr" >> /etc/ssh/sshd_config &&\
        print_log "INFO" "Ok set ssh config Ciphers aes128-ctr" && return 0
        print_log "ERROR" "Nok. aes128-ctr set ssh config Ciphers aes128-ctr: failed"
        return 1
   fi
}


########################
#     main program     #
########################
set_ciphers_aes128_config
