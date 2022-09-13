#!/bin/sh
# \
exec expect -- "$0" ${1+"$@"}

###################################################
#  用法: 脚本名 -i IP.地址 -p 密码 -t 超时时间 -P 端口 -b 是否开启后台运行模式 y/n -c 具体命令
###################################################
#  功能描述：
#  1:在远端的服务器上执行命令(使用-m ssh-cmd);
#  2:对于建立互信的环境可以不使用-p参数设置密码;
#  3:默认的用户名为root
#  4:默认的端口号为22
#  5:默认的脚本超时时间为120秒
#  6:执行结果以标准输出的形式输出
#  9:密码或用户名错误返回128
#  10:超时返回129
###################################################

#设置默认值
set port 22
set user "root"
set timeout  120
set password ""
set host ""
set command ""
set background "n"


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
    send_user "    -c <command>      Ssh Command\n"
    send_user "    -b <background>   Whether run in background, y/n, n as default\n"
    send_user "Sample:\n"
    send_user "$argv0 -i 127.0.0.1 -p pass -t 5 -m ssh-cmd -c ifconfig\n"
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
    } "-c" {
        set command [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } "-b" {
        set background [lindex $argv 1]
        set argv [lrange $argv 2 end]
    }  "-v" {
        send_user "Ver: 1.0.0.0\n"
        exit 0
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
if {"$command" == ""} {
    errlog "command is null" "yes" "1"
}

if {"$background" == "y"} {
    spawn ssh -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -t -p $port $user@$host "$command"
} else {
    spawn ssh -oServerAliveInterval=60 -oStrictHostKeyChecking=no -oVerifyHostKeyDNS=yes -oUserKnownHostsFile=/dev/null -p $port $user@$host "$command"
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
