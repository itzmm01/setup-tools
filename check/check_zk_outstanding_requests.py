#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_zk_common import get_zk_list, get_zk_pod_list, check_zk_pod_is_leader

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=5)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def zk_outstanding_requests(app_name=None, threshold=5):
    zk_list = get_zk_list(app_name)
    if not isinstance(zk_list, list): return 1
    for zk in zk_list:
        pod_list = get_zk_pod_list(zk)
        outstanding_requests = 0
        for pod in pod_list:
            if not check_zk_pod_is_leader(pod):
                # msg = "%s 不是leader，忽略该pod" % pod
                # logging.info(msg)
                continue

            cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|egrep zk_outstanding_requests" % pod
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg and len(ret_msg.split()) != 2:
                msg = "%s 获取zk_outstanding_requests失败：%s" % (cmd, ret_msg)
                logging.error(msg)
                return 1
            outstanding_requests = ret_msg.split()[1] if outstanding_requests <= ret_msg.split()[
                1] else outstanding_requests

            if int(outstanding_requests) >= int(threshold):
                msg = "%s 未处理的请求数量 %s，大于合理范围, 合理阈值: %s" % (pod, outstanding_requests, threshold)
                logging.error(msg)
                return 1

            msg = "%s zk_outstanding_requests异常数量 %s，处于合理范围, 合理阈值: %s" % (pod, outstanding_requests, threshold)
            logging.info(msg)


if __name__ == '__main__':
    exit(zk_outstanding_requests(app_name=args.app_name, threshold=args.threshold))
