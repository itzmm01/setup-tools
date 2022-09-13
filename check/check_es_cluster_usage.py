#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_es_common import get_es_list, get_es_pod_list, get_es_auth, get_es_user_pass

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=70)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_es_cluster_shard_percent(app_name=None, threshold=70):
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
            cmd = "kubectl -nsso exec -i %s -- sh -c '(curl -sS %s http://localhost:9200/_cat/allocation?v " \
                  "--connect-timeout 5|grep -v disk)'" % (pod, url)
            ret_msg = os.popen(cmd).readlines()
            if not ret_msg:
                msg = "%s 集群状态获取使用率失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue

            for line in ret_msg:
                if len(line.split()) <= 5:
                    msg = "%s 集群状态获取使用率失败：%s" % (pod, line)
                    logging.error(msg)
                    normal += 1
                    continue
                node = line.split()[-1].strip()
                current = line.split()[5].strip()
                if float(current) >= float(threshold):
                    msg = "%s 集群节点%s获取使用率 %.2f %%，大于合理阈值：%s %%" % (pod, node, float(current), threshold)
                    logging.error(msg)
                    normal += 1
                    continue

                msg = "%s 集群节点%s获取使用率 %.2f %%，处于合理阈值：%s %%" % (pod, node, float(current), threshold)
                logging.info(msg)
    return normal


if __name__ == '__main__':
    exit(check_es_cluster_shard_percent(app_name=args.app_name))
