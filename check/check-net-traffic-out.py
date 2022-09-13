#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='合理的阈值，默认值是5g', type=int, default=5242880000)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_net_traffic_in(threshold=5242880000):
    cmd = "cat /proc/net/dev|awk '{print $10}'|grep -E '^[0-9]' > /tmp/$USER/send_s;sleep 1;"
    cmd += "cat /proc/net/dev|awk '{print $10}'|grep -E '^[0-9]' > /tmp/$USER/send_e;"
    cmd += "pr -m -t /tmp/$USER/send_s /tmp/$USER/send_e|awk '{print $1,$2}'|awk '{if($2-$1 >100)print $2-$1}'"
    cmd += "|sort -nr|head -n1"
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取网络入流量异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "获取网络出流量占比值: %s, 合理情况应当小于阈值: %s" % (current, threshold)
    if float(current) > float(threshold):
        msg = "获取网络出流量占比值: %s, 大于合理阈值: %s" % (current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_net_traffic_in(args.threshold))
