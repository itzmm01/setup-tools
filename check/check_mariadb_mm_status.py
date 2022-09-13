#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import logging
import os
import sys
from check_mariadb_common import get_mariadb_list, get_mariadb_pod_list, get_mariadb_mode

if sys.version.split('.')[0] == "2":
    from imp import reload

    reload(sys)
    sys.setdefaultencoding('utf8')

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str, default="mariadb")
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_mariadb_mm_status(app_name="mariadb"):
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
        num = len(pod_list)
        for pod in pod_list:
            if mode == "MS":
                msg = "%s %s 主从模式，跳过检查" % (mariadb, pod)
                logging.info(msg)
                continue
            container = "galera" if mode != "MS" else "xenon"
            cmd = "kubectl -n sso exec -i %s -c %s -- " \
                  "mysql -e\"show status where Variable_name='wsrep_cluster_size' and Value=%s;\"" \
                  " | grep wsrep_cluster_size | wc -l" % (pod, container, num)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 获取mariadb的wsrep_cluster_size失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue

            current = ret_msg.strip()

            if int(current) != 1:
                msg = "%s 获取mariadb的当前wsrep_cluster_size,存在脑裂现象, 不等于mariadb的pod数量: %s" % (pod, num)
                logging.error(msg)
                normal += 1
                continue

            msg = "%s 获取mariadb的当前wsrep_cluster_size,状态正常,等于mariadb的pod数量: %s" % (pod, num)
            logging.info(msg)
    return normal


if __name__ == '__main__':
    exit(check_mariadb_mm_status(app_name=args.app_name))
