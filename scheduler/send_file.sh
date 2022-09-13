#!/bin/sh
# \
exec expect -- "$0" ${1+"$@"}

###################################################
#  用法: 脚本名 -i IP.地址 -p 密码 -t 超时时间 -s 源文件 -d 目标目录 -m 模式
###################################################
#  功能描述：
#  1:拷贝本地文件至远端服务器或者远端服务器拷贝到本地;
#  2:对于建立互信的环境可以不使用-p参数设置密码;
#  3:默认的用户名为root
#  4:默认的端口号为22
#  5:默认的脚本超时时间为120秒
#  6:执行结果以标准输出的形式输出
#  7:密码或用户名错误返回128
#  8:超时返回129
###################################################

#设置默认值
set port 22
set user "root"
set timeout  120
set password ""
set host ""
set src ""
set dst ""
set mode "out"

###############################################
# 显示帮助信息
###############################################
proc help {} {
    global argv0
    send_user "usage: $argv0\n"
    send_user "    -i <ip>           Host or IP\n"
    send_user "    -P <port>         Port. Default = 22\n"
    send_user "    -u <user>         UserName. Default = root\n"
    send_user "    -p <password>     Password.\n"
    send_user "    -t <timeout>      Timeout. Default = 120\n"
    send_user "    -s <src>          Scp Source File\n"
    send_user "    -d <dst>          Scp Destination File\n"
    send_user "    -m <mode>         Scp mode,support in or out. Default = out\n"
    send_user "    -v                Version\n"
    send_user "    -h                Help\n"
    send_user "Sample:\n"
    send_user "$argv0 -i 10.88.10.11 -p pass -s /etc/passwd -d /tmp/\n"
}

###############################################
# 输出错误日志
###############################################
proc errlog {errmsg h code} {
    global host
    send_user "ERROR: $errmsg on $host (${code}) \n"
    if {[string compare "$h" "yes"] == 0} {
        help
    }
    exit $code
}

#参数个数不能为0
if {[llength $argv] == 0} {
    errlog "argv is null" "yes" "1"
}

#参数解析
while {[llength $argv]>0} {
    set flag [lindex $argv 0]
    switch -- $flag "-i" {
        set host [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-P" {
        set port [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-u" {
        set user [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-p" {
        set password [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-t" {
        set timeout [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-s" {
        set src [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-d" {
        set dst [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-v" {
        send_user "Ver: 1.0.0.0\n"
        exit 0
    } "-m" {
        set mode [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-h" {
        help
        exit 0
    } default {
        set user [lindex $argv 0]
        set argv [lrange $argv 1 end]
        break
    }
}

#主机名或IP为空
if {"$host" == ""} {
    errlog "host is null" "yes" "1"
}

#执行命令
if {"$src" == "" || "$dst" == ""} {
    errlog "src or dst is null" "yes" "1"
}

if {"$mode" == "in"} {
    spawn scp -rp -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -P $port $user@$host:$src $dst
} else {
    spawn scp -rp -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -P $port $src $user@$host:$dst
}

#命令执行结果
expect {
    -nocase -re "please try again" {
        errlog "Bad Password/UserName, Or Account locked" "no" "128"
    }
    -nocase -re "password" {
        send "$password\r"
        exp_continue
    }
    timeout {
        errlog "Executing timeout" "no" "129"
    }
}

#获取命令执行结果
catch wait result
set ret [lindex $result 3]
exit $ret
