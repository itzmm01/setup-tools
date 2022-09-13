#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
import socket

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--ip', help='机器ip', type=str, default='1.1.1.1')
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_host_name(ip='1.1.1.1'):
    hostname = socket.gethostname()
    if not hostname:
        msg = "获取hostname异常: %s" % hostname
        logging.error(msg)
        return 1

    threshold = hostname
    ip = socket.gethostbyname(hostname)
    if not ip:
        msg = "获取ip异常: %s" % ip
        logging.error(msg)
        return 1

    current = str("tcs-%s" % ip).replace(".","-")
    last_msg = "机器的ip %s, 机器的名称: %s, 符合期望的机器名称: %s" % (ip, current, threshold)
    if current != threshold:
        msg = "机器的ip %s, 机器的名称: %s, 不符合期望的机器名称: %s" % (ip, current, threshold)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_host_name(args.ip))
