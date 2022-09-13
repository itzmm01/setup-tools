#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
################################################################

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

reset_rc_local() {
    echo '#!/bin/sh -e

exit 0
' > /etc/rc.local 
}
# output: 1/0
enable_rclocal() {
   os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
   if [ "$os_version" == "uos" ]; then
        [ -f /etc/rc.local ] || reset_rc_local
        chmod +x /etc/rc.local
        print_log "INFO" "rc.local enabled"
        return 0
   else
       if chmod +x /etc/rc.d/rc.local; then
           print_log "INFO" "rc.local enabled"
           return 0
       fi
       print_log "ERROR" "failed enable rc.local"
       return 1

   fi
}


########################
#     main program     #
########################
enable_rclocal
