#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_zk_common import get_zk_list, get_zk_pod_list, check_zk_pod_is_leader

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=100000)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def zk_znode(app_name=None, threshold=100000):
    zk_list = get_zk_list(app_name)
    if not isinstance(zk_list, list): return 1
    for zk in zk_list:
        pod_list = get_zk_pod_list(zk)
        zk_node_count = 0
        for pod in pod_list:
            if not check_zk_pod_is_leader(pod):
                # msg = "%s 不是leader，忽略该pod" % pod
                # logging.info(msg)
                continue

            cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|egrep zk_znode_count" % pod
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg and len(ret_msg.split()) != 2:
                msg = "%s 获取zk_znode_count失败：%s" % (cmd, ret_msg)
                logging.error(msg)
                return 1
            zk_node_count = ret_msg.split()[1] if zk_node_count <= ret_msg.split()[1] else zk_node_count

            if int(zk_node_count) >= int(threshold):
                msg = "%s zk_znode_count异常数量 %s，大于合理范围, 合理阈值: %s" % (pod, zk_node_count, threshold)
                logging.error(msg)
                return 1

            msg = "%s zk_znode_count异常数量 %s，处于合理范围, 合理阈值: %s" % (pod, zk_node_count, threshold)
            logging.info(msg)


if __name__ == '__main__':
    exit(zk_znode(app_name=args.app_name, threshold=args.threshold))
