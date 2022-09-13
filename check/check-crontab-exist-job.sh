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
    if [ $# -lt 1 ]; then
        print_log "INFO" "Usage: $baseName \"<job>\""
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName \"*/20 * * * * /usr/sbin/ntpdate time1.cloud.XXX.com > /dev/null &\""
        exit 1
    fi
}
# input: none
# output: 1/0
function check_jobs()
{
    check_input "$@"
    cron_job=$1
    cron_time=$(echo "$cron_job"|awk '{ for(i=1; i<=5; i++){ if ($i~"*") { $i="\\"$i} }; print $1"\\s*"$2"\\s*"$3"\\s*"$4"\\s*"$5}')
    #echo $cron_time
    cron_job_detailed=$(echo "$cron_job"|awk '{ for(i=1; i<=5; i++){ $i="" }; print $0 }' |sed -e 's/^\s*//g')
	print_log "INFO" "Check cron job status"
	cron_job_status=$(crontab -l |grep -E "$cron_job_detailed$|$cron_job_detailed\s*$"|grep -E "^$cron_time|^\s*$cron_time")
	if [ "$cron_job_status" == "" ];then
		print_log "ERROR" "Nok. $cron_job job is not in crontab."
		return 1
	else
		 print_log "INFO" "Ok. $cron_job job is in crontab."
	fi
}

########################
#     main program     #
########################
check_jobs "$@"
