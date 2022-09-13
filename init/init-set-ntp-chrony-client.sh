#!/bin/bash
################################################################
# Copyright (C) 1998-2019 Tencent Inc. All Rights Reserved
################################################################

# get work directory
workDir=$(cd "$(dirname "$0")" || exit; pwd)

# common functions
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

setup_chrony_client() {
    local ntps
    ntps=$(echo "$@" | tr ',' '\n' | tr ' ' '\n' | grep -v '^$' | sort | uniq | tr '\n' ' ')
    if [[ -n $ntps ]]; then
        :
    else
        if curl -s --connect-timeout 7 http://metadata.tencentyun.com>/dev/null 2>&1 || ntpdate time1.tencentyun.com >/dev/null 2>&1; then
            ntps="time1.tencentyun.com time2.tencentyun.com time3.tencentyun.com time4.tencentyun.com time5.tencentyun.com ntpupdate.tencentyun.com"
        elif ntpdate time1.cloud.tencent.com >/dev/null 2>&1; then
            ntps="time1.cloud.tencent.com time2.cloud.tencent.com time3.cloud.tencent.com time4.cloud.tencent.com time5.cloud.tencent.com ntpupdate.cloud.tencent.com"
        else
            print_log "ERROR" "no ntpserver"
            return 1
        fi
    fi
    print_log "INFO" "ntpserver: $ntps"
    /bin/rm -f /tmp/chrony.conf.client
    echo '# auto created by setuptools' >/tmp/chrony.conf.client
    for ntpip in $ntps; do
        echo "server $ntpip iburst" >>/tmp/chrony.conf.client
    done
    cat >>/tmp/chrony.conf.client<<EOF
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF
    os_version=`grep '^NAME' /etc/os-release |awk -F '=' '{print $NF}'|sed 's/"//g'`
    if [ "$os_version" == "uos" ]; then
        [ -x /usr/sbin/chronyd ] || dpkg -i $debDir/chrony_3.4-4+deb10u1_arm64.deb
        /bin/mv -f /etc/chrony/chrony.conf /etc/chrony/chrony.conf.autobak
        /bin/cp -f /tmp/chrony.conf.client /etc/chrony/chrony.conf
    else
        [ -x /usr/sbin/chronyd ] || in_rpm_install $rpmDir chrony libseccomp
        [ -f /etc/chrony.conf.bootstrap.autobak ] || {
            /bin/mv -f /etc/chrony.conf /etc/chrony.conf.bootstrap.autobak >/dev/null 2>&1
        }
        /bin/cp /tmp/chrony.conf.client /etc/chrony.conf
        echo 'OPTIONS="-4"' >/etc/sysconfig/chronyd
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
    print_log "INFO" "ntp client setup finish."
}

setup_chrony_client "$@" 
