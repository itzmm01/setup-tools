#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging

LOG_FORMAT = "%(asctime)s    [line-%(lineno)d]     [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)



def get_mariadb_list(app_name=None):
    cmd = "kubectl get mariadb -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'mariadb': cmd = "kubectl get mariadb -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的mariadb失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    mariadb_list = ret_msg.split()
    last_msg = "获取mariadb列表: %s" % (mariadb_list)
    logging.info(last_msg)
    return mariadb_list


def get_mariadb_pod_list(mariadb, app_name="mariadb"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (mariadb, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_list = ret_msg.split()
    # last_msg = "%s 当前运行的pod列表: %s" % (mariadb, pod_list)
    # logging.info(last_msg)
    return pod_list


def get_mariadb_mode(mariadb):
    cmd = "kubectl get mariadb %s -nsso -oyaml|grep ' mode:'" % mariadb
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的mariadb失败：%s (使用默认选项MM)" % (cmd, ret_msg)
        logging.info(msg)
        return 1

    mode = ret_msg.split(":")[1].strip() if len(ret_msg.split(":")) == 2 else None
    # last_msg = "获取mariadb %s的模式: %s" % (mariadb, mode)
    # logging.info(last_msg)
    return mode
