#!/usr/bin/python# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_postgres_common import get_postgres_list, get_postgres_pod_list, get_postgres_user, get_postgres_paas

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def postgres_cluster_status(app_name=None):
    postgres_list = get_postgres_list(app_name)
    for postgres in postgres_list:
        pod_list = get_postgres_pod_list(postgres)
        for pod in pod_list:
            user = get_postgres_user(pod)
            paas = get_postgres_paas(pod)
            cmd = "export PGPASSWORD=%s && psql -h localhost -U %s -d postgres -c\\\"SELECT datname , \
                a.rolname , pg_encoding_to_char(encoding) , datcollate , datctype , \
                pg_size_pretty(pg_database_size(datname)) FROM pg_database d , pg_authid a \
                WHERE d.datdba = a.oid AND datname NOT IN ('template0' ,'template1' ,'postgres' )\
                ORDER BY pg_database_size(datname) DESC;\\\"" % (paas, user)
            cmd = "kubectl exec -i %s -nsso -- bash -c \"%s\"" % (pod, cmd)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            if not ret_msg:
                msg = "%s 集群状态异常：%s" % (cmd, ret_msg)
                logging.error(msg)
                return 1

        msg = "%s 集群状态正常, 处于合理状态" % postgres
        logging.info(msg)


if __name__ == '__main__':
    postgres_cluster_status(app_name=args.app_name)
