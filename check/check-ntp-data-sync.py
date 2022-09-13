#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
import sys
import subprocess
import time

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--ip', help='需要比较的主机: 172.27.16.213', type=str)
parser.add_argument('--threshold', help='合理的阈值，默认值是1000ms', type=int, default=1000)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def execute_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    if p.returncode == 0:
        result_list = [cmd_res_compatible(i) for i in p.stderr.readlines()]
        return p.returncode, result_list
    else:
        return p.returncode, p.stderr.readlines()


def cmd_res_compatible(line):
    if sys.version.split('.')[0] == "2":
        return line.strip("\n")
    else:
        return line.decode("utf-8").strip("\n")


def check_ntp_data_sync(threshold=1000):
    cmd = "ntpq -pn|grep -Ev 'remote|=='|awk '{print $9}'|head -n1"
    cmd += "||chronyc -n -c sourcestats |awk -F',' '{print $7*1000}'|head -n1"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取时间ntp异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "跟时钟源的时间差距: %s ms, 处于合理阈值之内: %s ms" % (current, threshold)
    if abs(float(current)) > float(threshold):
        msg = "跟时钟源的时间差距: %s ms, 大于合理阈值: %s ms" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


def get_remote_date(ip, threshold=1000):
    cmd = """source /data/tce_dc/tcs/tools/setup-tools/cli.env && cli cmd -c "LANG=C date '+%s.%N'" -h {}""".format(ip)
    ret_code, ret_msg = execute_cmd(cmd)
    if ret_code != 0:
        msg = "获取时间ntp异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg[-2]
    disparity = abs((float(current) - time.time()) * 1000)
    last_msg = "跟时钟源的时间差距: %s ms, 处于合理阈值之内: %s ms" % (disparity, threshold)
    if disparity > 1000:
        msg = "跟时钟源的时间差距: %s ms, 大于合理阈值: %s ms" % (disparity, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(get_remote_date(args.ip, args.threshold))

