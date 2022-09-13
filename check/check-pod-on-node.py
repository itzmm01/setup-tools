#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_type', help='输入需要查找的app类型', type=str)
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str, default=None)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_pod_on_node(app_type, app_name=None):
    cmd = "kubectl get pods -nsso -owide -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $7}'" % (app_name, app_type)
    if not app_name:
        cmd = "kubectl get pods -nsso -owide -lapp.kubernetes.io/name=%s " \
              "--no-headers|grep -v exporter|awk '{print $7}'" % (app_type)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据获取app名称获取运行的机器失败：%s" % ret_msg
        logging.error(msg)
        return 1

    node_list = list(set(ret_msg.split()))
    node_list = ",".join(node_list)
    last_msg = "app %s, 运行的机器列表: %s" % (app_name, node_list)
    # logging.info(last_msg)
    return node_list


if __name__ == '__main__':
    print(check_pod_on_node(args.app_type, args.app_name))
