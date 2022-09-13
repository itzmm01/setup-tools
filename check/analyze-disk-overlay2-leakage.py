#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='判断内存泄漏的阈值，超过该阈值的容器占用磁盘过大，需要关注', type=int, default=50 * 1024)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def analyze_disk_overlay2_leakage(threshold=50 * 1024):
    cmd = "du -m /data/kubernetes/docker/overlay2/ --max-depth=1 2> /dev/null"
    cmd += "|awk '{if ($1 > 1000) print $0}'"
    cmd += "|sort -nr|grep -wv /data/kubernetes/docker/overlay2/|head -n1|awk '{print $1}'"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取占用磁盘top1容器异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg if ret_msg else 1

    last_msg = "获取占用磁盘top1容器占用磁盘: %.2f g, 处于合理阈值范围: %.2f g" % (float(current) / 1024, float(threshold) / 1024)
    if float(current) > float(threshold):
        msg = "获取占用磁盘top1容器占用磁盘: %.2f g, 大于合理阈值范围，需要重点关注: %.2f g" % (float(current) / 1024, float(threshold) / 1024)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(analyze_disk_overlay2_leakage(args.threshold))
