#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_es_common import get_es_list, get_es_pod_list, get_es_auth, get_es_user_pass

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_es_cluster_status(app_name=None):
    es_list = get_es_list(app_name)
    if es_list == 1:
        return
    normal = 0
    for es in es_list:
        auth = get_es_auth(es)
        user_pass = get_es_user_pass(es)
        url = "--user \"%s\"" % user_pass if auth == "AUTH" else ""
        pod_list = get_es_pod_list(es)
        for pod in pod_list:
            cmd = "kubectl -nsso exec -i %s -- sh -c '(curl -sS %s http://localhost:9200/_cluster/health?pretty " \
                  "--connect-timeout 5|grep status)'" % (pod, url)
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 集群状态失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue

            status = ret_msg.strip()
            if "green" not in status:
                msg = "%s 集群状态不是green：%s" % (pod, status)
                logging.error(msg)
                normal += 1
                continue

            msg = "%s 集群状态正常：%s" % (pod, status)
            logging.info(msg)
    return normal


if __name__ == '__main__':
    exit(check_es_cluster_status(app_name=args.app_name))
