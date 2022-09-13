#!/bin/bash
################################################################
# Copyright (C) 1998-2021 Tencent Inc. All Rights Reserved
# Name: check-os-kernel.sh
# Description: a script to check kernel version
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
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

print_usage() {
    print_log "INFO" "Usage:$baseName <kernel-version>"
    print_log "INFO" "e.g. $baseName 3.10.0-957.5.1.el7.x86_64"
}

check_input() {
    if [ $# -ne 1 ]; then
        #无输入参数
        print_log "ERROR" "Exactly 1 arguments are required"
        print_usage
        exit 1
    fi
}
# check if version number a is greater than or equal to version number b
v1_ge_v2() {
    local v1="$1"
    local v2="$2"
    read -r -d '' PYCODE << '_END_'
import sys

a_newer = 1
b_newer = -1
a_eq_b = 0

def stringToEVR(verstring):
    if verstring in (None, ''):
        return ('', '', '')
    i = verstring.find(':')
    if i == -1:
        epoch = ''
    else:
        epoch = verstring[:i]
    i += 1
    j = verstring.find('-', i)
    if j == -1:
        version = verstring[i:]
        release = ''
    else:
        version = verstring[i:j]
        release = verstring[j+1:]
    return (epoch, version, release)

def compare_evrs(evr_a, evr_b):
    a_epoch, a_ver, a_rel = evr_a
    b_epoch, b_ver, b_rel = evr_b
    if a_epoch != b_epoch:
        return a_newer if a_epoch > b_epoch else b_newer
    ver_comp = compare_versions(a_ver, b_ver)
    if ver_comp != a_eq_b:
        return ver_comp
    rel_comp = compare_versions(a_rel, b_rel)
    return rel_comp

def compare_versions(version_a, version_b):
    if version_a == version_b:
        return a_eq_b
    try:
        chars_a, chars_b = list(version_a), list(version_b)
    except TypeError:
        raise RpmError('Could not compare {0} to '
                       '{1}'.format(version_a, version_b))
    while len(chars_a) != 0 and len(chars_b) != 0:
        _check_leading(chars_a, chars_b)
        if chars_a[0] == '~' and chars_b[0] == '~':
            map(lambda x: x.pop(0), (chars_a, chars_b))
        elif chars_a[0] == '~':
            return b_newer
        elif chars_b[0] == '~':
            return a_newer
        if len(chars_a) == 0 or len(chars_b) == 0:
            break
        block_res = _get_block_result(chars_a, chars_b)
        if block_res != a_eq_b:
            return block_res
    if len(chars_a) == len(chars_b):
        return a_eq_b
    else:
        return a_newer if len(chars_a) > len(chars_b) else b_newer

def _check_leading(*char_lists):
    for char_list in char_lists:
        while (len(char_list) != 0 and not char_list[0].isalnum() and
                not char_list[0] == '~'):
            char_list.pop(0)

def _trim_zeros(*char_lists):
    for char_list in char_lists:
        while len(char_list) != 0 and char_list[0] == '0':
            char_list.pop(0)

def _pop_digits(char_list):
    digits = []
    while len(char_list) != 0 and char_list[0].isdigit():
        digits.append(char_list.pop(0))
    return digits

def _pop_letters(char_list):
    letters = []
    while len(char_list) != 0 and char_list[0].isalpha():
        letters.append(char_list.pop(0))
    return letters

def _compare_blocks(block_a, block_b):
    if block_a[0].isdigit():
        _trim_zeros(block_a, block_b)
        if len(block_a) != len(block_b):
            return a_newer if len(block_a) > len(block_b) else b_newer
    if block_a == block_b:
        return a_eq_b
    else:
        return a_newer if block_a > block_b else b_newer

def _get_block_result(chars_a, chars_b):
    first_is_digit = chars_a[0].isdigit()
    pop_func = _pop_digits if first_is_digit else _pop_letters
    return_if_no_b = a_newer if first_is_digit else b_newer
    block_a, block_b = pop_func(chars_a), pop_func(chars_b)
    if len(block_b) == 0:
        return return_if_no_b
    return _compare_blocks(block_a, block_b)

(e1, v1, r1) = stringToEVR(sys.argv[1])
(e2, v2, r2) = stringToEVR(sys.argv[2])
rc = compare_evrs((e1 or None, v1 or None, r1 or None),
                  (e2 or None, v2 or None, r2 or None))
if rc >= 0:
    # first ver >= second ver
    sys.exit(0)
sys.exit(1)
_END_
    pybin=$(which python2 2>/dev/null || which python3)
    if $pybin -c "$PYCODE" "$v1" "$v2"; then
        print_log "INFO" "check ok, $v1 is ge $v2"
        return 0
    fi
    print_log "ERROR" "check failed, $v1 is lt $v2"
    return 1
}

check_os_kernel() {
    check_input "$@"
    local input_ver=$1
    local svr_ver
    svr_ver=$(uname -r)
    if v1_ge_v2 "$svr_ver" "$input_ver"; then
        print_log "INFO" "Ok"
    else
        print_log "ERROR" "Nok"
        return 1
    fi
}

check_os_kernel "$@"
