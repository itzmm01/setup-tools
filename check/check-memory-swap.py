#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是0', type=int, default=0)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_memory_swap(threshold=0):
    cmd = "free -g | grep -i 'swap' |awk '{print $2}'"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取swap值异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "获取swap当前值: %s g, 应当等于合理阈值: %s g" % (current, threshold)
    if current == threshold:
        msg = "获取swap当前值: %s g, 大于合理阈值: %s g" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_memory_swap(args.threshold))
