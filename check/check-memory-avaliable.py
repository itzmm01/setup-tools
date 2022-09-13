#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import time
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是2', type=int, default=2)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_memory_avaliable(threshold=2):
    cmd = "free -g |grep Mem|awk '{print $NF}'"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取avaliable内存异常: " + str(ret_msg)
        logging.info(msg)
        return 1
    current = ret_msg
    last_msg = "获取当前avaliable内存: %s g, 合理情况应当大于阈值: %s g" % (current, threshold)
    if float(current) <= float(threshold):
        msg = "获取当前avaliable内存: %s g，小于合理阈值: %s g" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_memory_avaliable(args.threshold))
