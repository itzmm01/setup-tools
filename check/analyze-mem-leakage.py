#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='判断内存泄漏的阈值，超过该阈值的进程大概率有内存泄漏嫌疑，需要关注', type=int, default=10)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def analyze_mem_leakage(threshold=10):
    cmd = "ps auxw|sort -rn -k6|head -n1|awk '{print $6/1024/1024}'"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取占用内存top1进程异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "占用内存top1进程占用内存: %s g, 合理情况应当小于阈值: %s g" % (current, threshold)
    if float(current) > float(threshold):
        msg = "占用内存top1进程占用内存: %s, 大于合理阈值: %s g，需要关注确认是否有内存泄漏" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(analyze_mem_leakage(args.threshold))
