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

main() {
    print_log "INFO" "disable useless default cron"
    /bin/rm -f /etc/cron.daily/{makewhatis.cron,mlocate.cron,man-db.cron,makewhatis,mlocate,man-db} && print_log "INFO" "disable useless default cron: ok" && return 0
    print_log "INFO" "disable useless default cron: failed" && return 1
}

########################
#     main program     #
########################
main
