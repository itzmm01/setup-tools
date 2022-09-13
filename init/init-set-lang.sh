#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
# Name: init-set-lang.sh
# Description: a script to set $LANG
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

# desc: print how to use
function print_usage()
{
    print_log "INFO" "Usage: $baseName <lang_code>"
    print_log "INFO" "  <lang_code>: required language, e.g. en_US.utf8, zh_CN.utf8, ..."
    print_log "INFO" "Example: $baseName en_US.utf8"
}

# desc: set LANG
# input: lang_code
# output: 1/0
set_lang() {
    local lang_code="$1"
    local lang_tmp
    [[ -n $lang_code ]] || {
        print_log "ERROR" "usage: $0 LANG_CODE"
        print_usage
        return 1
    }
    lang_tmp=$(echo "$lang_code"| sed 's/-//g')
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
    if ! localectl list-locales | grep -qi "$lang_tmp"; then
        if localectl list-locales | grep -qi "$lang_code"; then
            lang_tmp=$(localectl list-locales | grep -wiF "$lang_code")
        else
            print_log "ERROR" "bad lang: $lang_code / $lang_tmp"
            return 1
        fi
    fi
    if grep -q '^LANG=' /etc/profile; then
        sed -i "s/^LANG=.*$/LANG=$lang_tmp/" /etc/profile
    fi
    if grep -q '^export LANG' /etc/profile; then
        sed -i "s/^export LANG=.*$/export LANG=$lang_tmp/" /etc/profile
    else
        [[ -n "$(tail -c1 /etc/profile )" ]] && echo >>/etc/profile
        echo "export LANG=$lang_tmp" >>/etc/profile
    fi
    echo "LANG=$lang_tmp" >/etc/locale.conf
    if localectl set-locale LANG="$lang_tmp"; then
        print_log "INFO" "OK"
        return 0
    else
        print_log "ERROR" "Nok"
    fi
    return 1
}


########################
#     main program     #
########################
set_lang "$*"
