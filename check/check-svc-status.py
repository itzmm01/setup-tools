#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--svc_name', help='svc名称', type=str, default='infrastore')
parser.add_argument('--svc_type', help='svc类型', type=str, default='LoadBalance')
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_svc_status(svc_name='infrastore', svc_type='LoadBalance'):
    cmd = "kubectl get svc -A|grep %s |grep %s|grep -i pending|wc -l" % (svc_name, svc_type)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获异常: %s" % ret_msg
        logging.error(msg)
        return 1
    current = ret_msg

    last_msg = "pending中的svc: %s 个, 处于合理阈值之内: %s 个" % (current, 0)
    if int(current) >= 1:
        msg = "pending中的svc: %s 个, 大于合理阈值: %s 个" % (current, 0)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_svc_status(args.svc_name, args.svc_type))
