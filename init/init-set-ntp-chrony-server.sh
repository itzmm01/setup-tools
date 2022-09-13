#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
################################################################

# get work directory
workDir=$(cd "$(dirname "$0")" || exit; pwd)

rpmDir=$(cd "$workDir/../deps/rpms" || exit; pwd)
debDir=$(cd "$workDir/../deps/debs" || exit; pwd)

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

baseName=$(basename $0)
function check_input ()
{
    if [ $# -lt 1 ];then
        print_log "INFO" "Usage: $baseName <ip> [sync servers]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 127.0.0.1"
        print_log "INFO" "  $baseName 127.0.0.1 time1.cloud.tencent.com,time2.cloud.tencent.com"
        exit 1
    fi
}

# install self packaged rpms from local dir
in_rpm_install() {
    local rpmDir=$1
    shift
    local pkgs="$@"
    for pkg in $pkgs; do
        rpmname=$(find -L $rpmDir -name "$pkg-*.rpm" 2>/dev/null | grep -E "$(uname -i)|noarch" | sort -V | tail -1)
        rpms="$rpms $rpmname"
    done
    if yum -y localinstall --disablerepo=* $rpms >/dev/null 2>&1; then
        print_log "INFO" "install $rpms success"
        return 0
    fi
    print_log "ERROR" "install $rpms failed"
    return 1
}

setup_chrony_server() {
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    check_input "$@"
    local bindip=$1
    shift
    local syncserver="$@"
    [[ -n $bindip ]] || {
        print_log "ERROR" "no local bindip given"
        return 1
    }
    echo '# auto created by setuptools' >/tmp/chrony.conf.server
    echo '# auto created by setuptools' >/tmp/chrony.conf.server.uos
    if [[ $syncserver ]]; then
      ntps=$(echo "$syncserver" | tr ',' '\n' | tr ' ' '\n' | grep -v '^$' | sort | uniq | tr '\n' ' ')
      print_log "INFO" "syncronized ntpserver: $ntps"
      for ntpip in $ntps; do
          if [ "$os_version" == "uos" ]; then
              echo "server $ntpip iburst" >>/tmp/chrony.conf.server.uos
          else
              echo "server $ntpip iburst" >>/tmp/chrony.conf.server
          fi
      done
    fi

    cat >>/tmp/chrony.conf.server<<EOF
local stratum 8
manual
allow
smoothtime 400 0.01
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindaddress $bindip
bindcmdaddress 127.0.0.1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF
    cat >>/tmp/chrony.conf.server.uos<<EOF
local stratum 10
makestep 1.0 3
allow 0.0.0.0/0
rtcsync

keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/drift
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF
    if [ "$os_version" == "uos" ]; then
        [ -x /usr/sbin/chronyd ] || dpkg -i $debDir/chrony_3.4-4+deb10u1_arm64.deb
        /bin/mv -f /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bootstrap.autobak >/dev/null 2>&1
        /bin/cp -f /tmp/chrony.conf.server.uos /etc/chrony/chrony.conf
    else
        [ -x /usr/sbin/chronyd ] || in_rpm_install $rpmDir chrony libseccomp
        echo 'OPTIONS="-4"' >/etc/sysconfig/chronyd
        /bin/mv -f /etc/chrony.conf /etc/chrony.conf.bootstrap.autobak >/dev/null 2>&1
        /bin/cp /tmp/chrony.conf.server /etc/chrony.conf
    fi
    [ -x /usr/sbin/chronyd ] || {
        echo "install chrony failed"
        return 1
    }

    systemctl disable ntpd >/dev/null 2>&1
    systemctl enable chronyd >/dev/null 2>&1
    systemctl stop ntpd >/dev/null 2>&1
    systemctl restart chronyd >/dev/null 2>&1
    timedatectl
    print_log "INFO" "ntp server setup finish."
}

setup_chrony_server "$@" 
