#!/bin/bash
################################################################
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserved
# Name: check-language.sh
# Description: a script to check if language setting on current
# machine meets requirement
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
baseName=`basename $0`


# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <lang_code>"
    print_log "INFO" "  <lang_code>: required language, e.g. en_US.utf8, zh_CN.utf8, ..."
    print_log "INFO" "Example: $baseName en_US.utf8"
}

# desc: check if language is ok
# input: lang
# output: 1/0
function check_language()
{

    if [ $# -ne 1 ]; then
        print_log "ERROR" "Exactly one parameter is required."
        print_usage
        return 1
    fi

    print_log "INFO" "Check if language is ok."
    lang_code=$1
    lang_tmp=$(echo "$lang_code" | sed 's/-//g')
    local lang_tmp_p=$(echo "$lang_tmp" | awk -F'.' '{print $1}')
    local lang_tmp_s=$(echo "$lang_tmp" | awk -F'.' '{print $2}' | tr '[A-Z]' '[a-z]')
    local lang_tmp_h=$(echo "$lang_tmp_p" | awk -F'_' '{print $1}' | tr '[A-Z]' '[a-z]')
    local lang_tmp_e=$(echo "$lang_tmp_p" | awk -F'_' '{print $2}'|tr '[a-z]' '[A-Z]')
    if [[ -n $lang_tmp_e ]]; then
        lang_tmp_p="${lang_tmp_h}_${lang_tmp_e}"
    fi
    if [[ -n $lang_tmp_s ]]; then
        lang_tmp="${lang_tmp_p}.${lang_tmp_s}"
    else
        lang_tmp="$lang_tmp_p"
    fi

    [ -f /etc/profile ] && source /etc/profile
    currentLang=$(echo $LANG)
    lang_t=$(echo "$currentLang" | sed 's/-//g')
    local lang_t_p=$(echo "$lang_t" | awk -F'.' '{print $1}')
    local lang_t_s=$(echo "$lang_t" | awk -F'.' '{print $2}' | tr '[A-Z]' '[a-z]')
    local lang_t_h=$(echo "$lang_t_p" | awk -F'_' '{print $1}' | tr '[A-Z]' '[a-z]')
    local lang_t_e=$(echo "$lang_t_p" | awk -F'_' '{print $2}'|tr '[a-z]' '[A-Z]')
    if [[ -n $lang_t_e ]]; then
        lang_t_p="${lang_t_h}_${lang_t_e}"
    fi
    if [[ -n $lang_t_s ]]; then
        lang_t="${lang_t_p}.${lang_t_s}"
    else
        lang_t="$lang_t_p"
    fi
    print_log "INFO" "Current language: $lang_t, required language: $lang_tmp"
    if [[ $lang_tmp = "$lang_t" ]]; then
        print_log "INFO" "Ok."
        return 0
    fi
    print_log "WARNING" "Nok."
    return 1
}


########################
#     main program     #
########################
check_language $*
