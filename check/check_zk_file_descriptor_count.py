#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_zk_common import get_zk_list, get_zk_pod_list, check_zk_pod_is_leader

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=80)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def zk_open_file_descriptor_count(app_name=None, threshold=80):
    zk_list = get_zk_list(app_name)
    if not isinstance(zk_list, list): return 1
    for zk in zk_list:
        pod_list = get_zk_pod_list(zk)
        current = 0
        for pod in pod_list:
            if not check_zk_pod_is_leader(pod):
                # msg = "%s 不是leader，忽略该pod" % pod
                # logging.info(msg)
                continue

            cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|egrep zk_max_file_descriptor_count" % pod
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg and len(ret_msg.split()) != 2:
                msg = "%s 获取最大文件描述数量zk_max_file_descriptor_count失败：%s" % (cmd, ret_msg)
                logging.error(msg)
                return 1
            zk_max_file_descriptor_count = ret_msg.split()[1]

            cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|egrep zk_open_file_descriptor_count" % pod
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg and len(ret_msg.split()) != 2:
                msg = "%s 获取打开的文件描述数量zk_open_file_descriptor_count失败：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1
            zk_open_file_descriptor_count = ret_msg.split()[1]

            msg = "%s 打开的文件描述数量zk_open_file_descriptor_count = %s, 当前最大文件描述数量zk_max_file_descriptor_count = %s" % (
                pod, zk_open_file_descriptor_count, zk_max_file_descriptor_count)
            logging.info(msg)

            current = float(zk_open_file_descriptor_count) / float(zk_max_file_descriptor_count) if float(
                zk_open_file_descriptor_count) / float(zk_max_file_descriptor_count) >= current else current
            current = current * 100

            if int(current) >= int(threshold):
                msg = "%s 获取打开的文件描述数量zk_open_file_descriptor_count和最大文件描述数量zk_max_file_descriptor_count的比例: %s, 大于合理范围, 合理阈值: %s %%" % (
                    pod, current, threshold)
                logging.error(msg)
                return 1

            msg = "%s 获取打开的文件描述数量zk_open_file_descriptor_count和最大文件描述数量zk_max_file_descriptor_count的比例: %s, 处于合理范围, 合理阈值: %s %%" % (
                zk, current, threshold)
            logging.info(msg)


if __name__ == '__main__':
    exit(zk_open_file_descriptor_count(app_name=args.app_name))
