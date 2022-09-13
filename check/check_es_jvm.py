#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_es_common import get_es_list, get_es_pod_list, get_es_auth, get_es_user_pass

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找es', type=str, default="es")
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=80)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_jvm(args):
    es_list = get_es_list(args.app_name)
    if es_list == 1:
        return
    normal = 0
    for es in get_es_list():
        pod_list = get_es_pod_list(es)
        for pod in pod_list:
            cmd = 'kubectl -nsso exec -i %s -- sh -c "ps aux|grep elasticsearch|grep -v grep|awk \'{print \$4}\'"' % \
                  pod
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 获取jvm使用率：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue
            msg = "%s jvm使用率：%s 需要小于 %s" % (pod, ret_msg, args.threshold)
            if eval("%s > %s" % (ret_msg, args.threshold)):
                logging.error(msg)
                normal += 1

            else:
                logging.info(msg)


check_jvm(args)
