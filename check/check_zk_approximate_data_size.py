#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_zk_common import get_zk_list, get_zk_pod_list, check_zk_pod_is_leader

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=1073741824)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def zk_approximate_data_size(app_name=None, threshold=1073741824):
    zk_list = get_zk_list(app_name)
    if not isinstance(zk_list, list): return 1
    for zk in zk_list:
        pod_list = get_zk_pod_list(zk)
        zk_data_size = 0
        for pod in pod_list:
            if not check_zk_pod_is_leader(pod):
                # msg = "%s 不是leader，忽略该pod" % pod
                # logging.info(msg)
                continue

            cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|egrep zk_approximate_data_size" % pod
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg and len(ret_msg.split()) != 2:
                msg = "%s 获取快照体积zk_approximate_data_size失败：%s" % (cmd, ret_msg)
                logging.error(msg)
                return 1
            zk_data_size = ret_msg.split()[1] if zk_data_size <= ret_msg.split()[
                1] else zk_data_size

            if int(zk_data_size) >= int(threshold):
                msg = "%s 快照体积zk_approximate_data_size异常数量 %s g，大于合理范围, 合理阈值: %s g" % (
                    pod, float(zk_data_size) / 1073741824, float(threshold) / 1073741824)
                logging.error(msg)
                return 1

            msg = "%s 快照体积zk_approximate_data_size异常数量 %s g，处于合理范围, 合理阈值: %s g" % (
                pod, float(zk_data_size) / 1073741824, float(threshold) / 1073741824)
            logging.info(msg)


if __name__ == '__main__':
    exit(zk_approximate_data_size(app_name=args.app_name, threshold=args.threshold))
