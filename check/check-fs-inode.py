#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是80', type=int, default=80)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_fs_inode(threshold=80):
    cmd = "df -i|awk '{print $5}'|sed 's/%//g'|sort -nr |head  -n1"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取inode异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "获取inode占比值: %s %% , 合理情况应当小于阈值: %s %%" % (current, threshold)
    if float(current) > float(threshold):
        msg = "获取inode占比值: %s %%, 大于合理阈值: %s %%" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_fs_inode(args.threshold))
