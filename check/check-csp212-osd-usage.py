#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='ceph的集群使用率，默认值是70', type=int, default=70)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_csp_osd_usage(threshold=70):
    cmd = "sudo ceph -c $(ls /data/cos/ceph.*.conf | head -1) df detail |grep TOTAL|awk '{print $NF}'"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取CPU核数异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg
    last_msg = "csp集群的使用率: %s %%, 处于合理阈值范围: %s %%" % (current, threshold)
    if float(current) >= float(threshold):
        msg = "csp集群的使用率: %s, 大于合理阈值范围: %s %%" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_csp_osd_usage(args.threshold))
