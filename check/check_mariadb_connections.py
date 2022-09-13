#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import logging
import os
from check_mariadb_common import get_mariadb_list, get_mariadb_pod_list, get_mariadb_mode

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str, default="mariadb")
parser.add_argument('-threshold', help='输入合理阈值', type=float, default=0.8)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_mariadb_max_connections(app_name="mariadb", threshold=0.8):
    mariadb_list = get_mariadb_list(app_name)
    normal = 0
    for mariadb in mariadb_list:
        mode = get_mariadb_mode(mariadb=mariadb)
        pod_list = get_mariadb_pod_list(mariadb)
        if not pod_list:
            msg = "%s 获取mariadb的pod失败：%s" % (mariadb)
            logging.error(msg)
            normal += 1
            continue
        for pod in pod_list:
            container = "galera" if mode != "MS" else "xenon"
            cmd = "kubectl -n sso exec -i %s -c %s -- " \
                  "mysql -e\"show variables like 'max_connections'\"" \
                  " | grep max_connections | awk '{print $NF}'" % (pod, container)
            # logging.info(cmd)
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 获取mariadb的最大连接数失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue
            max = ret_msg.strip()

            cmd = "kubectl -n sso exec -i %s -c %s -- " \
                  "mysql -e\"show status like '%%threads_conn%%'\"" \
                  " | grep Threads_connected | awk '{print $NF}'" % (pod, container)
            # logging.info(cmd)
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 获取mariadb的当前连接数失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue

            current = ret_msg.strip()

            if float(current) >= float(max) * threshold:
                msg = "%s 获取mariadb的当前连接数: %.2f, 最大连接数: %.2f, 大于合理阈值范围: %.2f %%" % (
                    pod, float(current), float(max), threshold * 100)
                logging.error(msg)
                normal += 1
                continue

            msg = "%s 获取mariadb的当前连接数: %.2f, 最大连接数: %.2f, 处于合理阈值范围: %.2f %%" % (
                pod, float(current), float(max), threshold * 100)
            logging.info(msg)
    return normal


if __name__ == '__main__':
    exit(check_mariadb_max_connections(app_name=args.app_name, threshold=args.threshold))
