#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是20', type=int, default=20)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_fs_zombie(threshold=20):
    cmd = "ps -A -ostat,ppid,pid,cmd |grep -e '^[Zz]'|wc -l"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取僵死进程异常: %s" % ret_msg
        logging.error(msg)
        return 1
    fs_inode = ret_msg

    last_msg = "僵死进程数量值: %s, 处于合理阈值范围: %s" % (fs_inode, threshold)
    if float(fs_inode) > float(threshold):
        msg = "僵死进程数量值: %s, 大于合理阈值范围: %s" % (fs_inode, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_fs_zombie(args.threshold))
