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
parser.add_argument('-threshold', help='输入合理阈值', type=int, default=20)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_mariadb_db_size(app_name="mariadb", threshold=20):
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
                  "mysql -e \"SELECT TABLE_SCHEMA, SUM(DATA_LENGTH) AS DATA FROM information_schema.tables " \
                  "GROUP BY TABLE_SCHEMA ORDER BY DATA DESC LIMIT 1\G;\"" \
                  " | grep DATA | awk -F ':' '{print $NF}'" % (pod, container)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().strip()
            if not ret_msg:
                msg = "%s 获取mariadb的dbsize失败：%s" % (pod, ret_msg)
                logging.error(msg)
                normal += 1
                continue

            current = ret_msg.strip()
            if float(current) / 1073741824 >= threshold:
                msg = "%s 获取mariadb的dbsize: %.2f g, 大于合理阈值范围: %.2f g" % (
                    pod, float(current) / 1073741824, threshold)
                logging.error(msg)
                normal += 1
                continue

            msg = "%s 获取mariadb的dbsize: %.2f g, 处于合理阈值范围: %.2f g" % (
                pod, float(current) / 1073741824, threshold)
            logging.info(msg)
    return normal


if __name__ == '__main__':
    exit(check_mariadb_db_size(app_name=args.app_name, threshold=args.threshold))
