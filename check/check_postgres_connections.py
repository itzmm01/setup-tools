#!/usr/bin/python# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_postgres_common import get_postgres_list, get_postgres_pod_list, get_postgres_user, get_postgres_paas

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
parser.add_argument('-threshold', help='输入对应的阈值', type=int, default=80)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def postgres_cluster_connections(app_name=None, threshold=80):
    postgres_list = get_postgres_list(app_name)
    for postgres in postgres_list:
        current, max_connections = 0, 0
        pod_list = get_postgres_pod_list(postgres)
        for pod in pod_list:
            user = get_postgres_user(pod)
            paas = get_postgres_paas(pod)
            cmd = "export PGPASSWORD=%s && psql -h localhost -U %s -d postgres -c\\\"select count(1) from pg_stat_activity;\\\"" % (
                paas, user)
            cmd = "kubectl exec -i -c postgresql %s -nsso -- bash -c \"%s\"" % (pod, cmd)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg:
                msg = "%s 获取当前集群连接数异常：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1
            current = ret_msg.split()[2].lstrip().rstrip()
            cmd = "export PGPASSWORD=%s && psql -h localhost -U %s -d postgres -c\\\"show max_connections;\\\"" % (
                paas, user)
            cmd = "kubectl exec -i -c postgresql %s -nsso -- bash -c \"%s\"" % (pod, cmd)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg:
                msg = "%s 获取当前集群设置的最大连接数：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1
            max_connections = ret_msg.split()[2].lstrip().rstrip()

            if float(current) >= float(max_connections) * threshold / 100:
                msg = "%s 获取当前的连接数 %s, 集群设置的最大连接数：%s, 大于合理范围, 合理阈值: %s %%" % (pod, current, max_connections, threshold)
                logging.error(msg)
                return 1

            msg = "%s 获取当前的连接数 %s, 集群设置的最大连接数：%s, 处于合理范围, 合理阈值: %s %%" % (pod, current, max_connections, threshold)
            logging.info(msg)

        msg = "%s 获取当前的连接数 %s, 集群设置的最大连接数：%s, 处于合理范围, 合理阈值: %s %%" % (postgres, current, max_connections, threshold)
        logging.info(msg)


if __name__ == '__main__':
    postgres_cluster_connections(app_name=args.app_name, threshold=args.threshold)
