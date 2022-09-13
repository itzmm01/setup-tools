#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument("--N", required=False, help='最近负载的分钟数，选项1/5/15，默认值是5', type=int, default=5)
parser.add_argument('--threshold', help='负载跟CPU核数的百分比，默认值是100', type=int, default=100)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_load_average(N=5, threshold=100):
    """
    1.获取cpu个数：grep -c ^processor /proc/cpuinfo
    2.获得对应分钟数的负载
        5分钟： uptime | awk '{print $(NF-2)}' | tr -d ','
        10分钟：uptime | awk '{print $(NF-1)}' | tr -d ','
        15分钟：uptime | awk '{print $(NF)}' | tr -d ','
    3.判断获得负载值是否小于cpu个数
    :param N: 分钟数，可选值为5，10，15
    :param threshold: 阈值，百分比
    :return:
    """
    # 首先获取CPU个数
    cmd = "grep -c ^processor /proc/cpuinfo"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取CPU核数异常: %s" % ret_msg
        logging.error(msg)
        return 1
    cpu_total = ret_msg

    # 获取最近1/5/15分钟负载
    if N == 15:
        cmd = "uptime | awk '{print $(NF)}' | tr -d ','"
    elif N == 5:
        cmd = "uptime | awk '{print $(NF-1)}' | tr -d ','"
    else:
        cmd = "uptime | awk '{print $(NF-2)}' | tr -d ','"

    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取%s分钟系统负载异常" % N
        logging.error(msg)
        return 1
    load_average = ret_msg
    last_msg = "最近%s分钟系统负载: %s, 处于合理阈值范围（机器cpu核数）: %s" % (N, ret_msg, cpu_total)
    if float(load_average) > float(float(cpu_total) * threshold / 100):
        msg = "最近%s分钟系统负载: %s, 大于合理阈值范围（机器cpu核数）: %s" % (N, ret_msg, cpu_total)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_load_average(args.N, args.threshold))
