#!/usr/bin/python
# -*- coding: UTF-8 -*-
import subprocess
import sys
import time
import base_comm


def sync_date(ntp_server=None, diff_ms=500):
    print(ntp_server)
    """
        执行步骤：
            1. 获取服务器时间
                如果没有配置ntp_server, 执行命令：LANG=C date '+%s.%N'
                如果配置了ntp_server，执行命令：clockdiff {ntp_server} | awk '{{if($3>= 0) print $3; else print -$3}}'
            2.判断与当前服务器时间差值是否小于diff_ms

        :param ntp_server: 参照的ntp 服务器
        :param diff_ms: 误差最大值，单位毫秒
        :param exclude_ips: 过滤的Ip，即不做该项巡检
        :return:
        """

    if ntp_server is None:
        try:
            result = base_comm.execute_cmd("LANG=C date '+%s.%N'")
            now_time = time.time()
        except Exception as e:
            return 1, "Server is unreachable: %s" % str(e)

        data = result[-1]

        if result[0] != 0:
            return 1, "Check datetime error: %s" % data
        if isinstance(data, bytes):
            data = data.decode("utf-8").strip("\n").strip()
        server_time = float(data)
        diff = int((server_time - now_time) * 1000)
        if abs(diff) >= diff_ms:
            msg = "服务器时间误差大于1秒: {}".format(diff)
            return 1, msg
        else:
            msg = "服务器时间误差小于1秒: {}".format(diff)
            return 0, msg
    else:
        print(1)
        cmd = "clockdiff {} | awk '{{if($3>= 0) print $3; else print -$3}}'".format(ntp_server)
        ret_code, ret_msg = base_comm.execute_cmd(cmd)
        if ret_code != 0:
            msg = "执行clockdiff命令失败：{}".format(ret_msg)
            return 1, msg
        try:
            diff = int(float(ret_msg[0]))
        except ValueError:
            # 使用clockdiff命令方式无法解析域名的情况下，通过ntpq -p 来查看吧
            if (
                    "my host not found" in ret_msg
                    or "Name or service not known" in ret_msg
            ):
                cmd = "systemctl is-active ntpd &>>/dev/null"
                cmd += "&& ( ntpq -pn|grep -A1 '==='|tail -1|awk '{print $9}' )"
                cmd += "|| (chronyc -n -c sourcestats |head -1|awk -F',' '{print $7*1000}')"

                ret_code, ret_msg = base_comm.execute_cmd(cmd)
                if ret_code != 0:
                    msg = "执行clockdiff命令失败：{}".format(ret_msg)
                    return 1, msg

                if ret_msg == "":
                    msg = "执行clockdiff命令失败：{}".format(ret_msg)
                    return 1, msg

                try:
                    diff = float(ret_msg[0].strip())
                except ValueError:
                    msg = "执行命令：{}返回信息与预期不符: {}".format(cmd, ret_msg)
                    return 1, msg
            else:
                msg = "clockdiff 返回值与预期不符合：{}".format(ret_msg)
                return 1, msg

        if abs(diff) > diff_ms:
            msg = "时间差与ntp server[{}]大于{}ms - 实际：{}ms".format(ntp_server, diff_ms, diff)
            return 1, msg
        else:
            msg = "时间差与ntp server[{}]小于{}ms - 实际： {}ms".format(ntp_server, diff_ms, diff)
            return 0, msg


if len(sys.argv) > 1:
    code, msg = sync_date(sys.argv[1])
    if code != 0:
        print(msg)
        sys.exit(1)
    else:
        print(msg)
else:
    print("%s 127.0.0.1" % (sys.argv[0]))
