#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_zk_common import get_zk_list, get_zk_pod_list, check_zk_pod_is_leader

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_zk_has_leader(app_name=None):
    zk_list = get_zk_list(app_name)
    if not isinstance(zk_list, list): return 1
    for zk in zk_list:
        pod_list = get_zk_pod_list(zk)
        has_leader = False
        for pod in pod_list:
            if check_zk_pod_is_leader(pod):
                msg = "%s 当前角色：leader" % (pod)
                logging.info(msg)
                has_leader = True

        if not has_leader:
            msg = "%s 集群异常，没有leader" % zk
            logging.error(msg)
            return 1

        msg = "%s 集群正常，拥有leader" % zk
        logging.info(msg)


if __name__ == '__main__':
    exit(check_zk_has_leader(app_name=args.app_name))
