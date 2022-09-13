#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是1000ms', type=int, default=1000)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_disk_iowait(threshold=1000):
    cmd = "cat /proc/diskstats|awk '{print $7+$11,$4+$8}' > /tmp/$USER/iowait_s;"
    cmd += "sleep 1;"
    cmd += "cat /proc/diskstats|awk '{print $7+$11,$4+$8}' > /tmp/$USER/iowait_e;"
    cmd += "pr -m -t /tmp/$USER/iowait_s /tmp/$USER/iowait_e|awk '{if($4-$2==0)print 0;else print ($3-$1)/($4-$2)}'"
    cmd += "|sort -nr |head  -n1"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取iowait异常: %s" % ret_msg
        logging.error(msg)
        return 1
    iowait = ret_msg

    last_msg = "获取磁盘ioawait值: %s ms, 处于合理阈值范围: %s ms" % (iowait, threshold)
    if float(iowait) > float(threshold):
        msg = "获取磁盘ioawait值: %s ms, 大于合理阈值: %s ms" % (iowait, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_disk_iowait(args.threshold))
