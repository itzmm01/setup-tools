#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def get_postgres_list(app_name=None):
    cmd = "kubectl get postgres -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'postgres': cmd = "kubectl get postgres -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的postgres失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    postgres_list = ret_msg.split()
    last_msg = "获取postgres列表: %s" % (postgres_list)
    logging.info(last_msg)
    return postgres_list


def get_postgres_pod_list(postgres, app_name="postgres"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (postgres, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_list = ret_msg.split()
    # last_msg = "%s 当前运行的pod列表: %s" % (postgres, pod_list)
    # logging.info(last_msg)
    return pod_list


def get_postgres_pod_list(postgres, app_name="postgres"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (postgres, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_list = ret_msg.split()
    # last_msg = "%s 当前运行的pod列表: %s" % (postgres, pod_list)
    # logging.info(last_msg)
    return pod_list


def get_postgres_user(pod):
    cmd = "kubectl -nsso get pod %s -oyaml|grep -A1 PATRONI_SUPERUSER_USERNAME|grep value|awk -F ':' '{print $2}'" % (
        pod)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 获取账号失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1
    return ret_msg


def get_postgres_paas(pod):
    cmd = "kubectl -nsso get pod %s -oyaml|grep -A1 PATRONI_SUPERUSER_PASSWORD|grep value|awk -F':' '{print $2}'" % (
        pod)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 获取账号失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1
    return ret_msg
