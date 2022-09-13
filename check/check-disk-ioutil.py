#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是60', type=int, default=60)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_disk_ioutil(threshold=60):
    cmd = "cat /proc/diskstats|awk '{print $13}' > /tmp/$USER/iouitl_s;sleep 1;"
    cmd += "cat /proc/diskstats|awk '{print $13}' > /tmp/$USER/iouitl_e;"
    cmd += "pr -m -t /tmp/$USER/iouitl_s /tmp/$USER/iouitl_e|awk '{print $1,$2}'|awk '{print ($2-$1)/10}'"
    cmd += "|sort -nr |head -n1"
    i = 0
    while i <= 10:
        i = i + 1
        ret_msg = os.popen(cmd).read().lstrip().rstrip()
        if not ret_msg:
            msg = "获取磁盘ioutil异常: %s" % ret_msg
            logging.error(msg)
            return 1
        fs_inode = ret_msg

        last_msg = "获取磁盘ioutil当前值: %s %%, 处于合理阈值范围: %s %%" % (fs_inode, threshold)
        if float(fs_inode) > float(threshold):
            msg = "获取磁盘ioutil当前值: %s %%, 大于合理阈值: %s %%" % (fs_inode, threshold)
            logging.error(msg)
            return 1
        logging.info(last_msg)
        return 0


if __name__ == '__main__':
    exit(check_disk_ioutil(args.threshold))
