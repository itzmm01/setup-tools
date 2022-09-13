#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def get_zk_list(app_name=None):
    cmd = "kubectl get zk -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'zk': cmd = "kubectl get zk -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的zk失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    zk_list = ret_msg.split()
    last_msg = "获取zk列表: %s" % (zk_list)
    logging.info(last_msg)
    return zk_list


def get_zk_pod_list(zk, app_name="zookeeper"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (zk, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_list = ret_msg.split()
    # last_msg = "%s 当前运行的pod列表: %s" % (zk, pod_list)
    # logging.info(last_msg)
    return pod_list


def check_zk_pod_is_leader(pod):
    is_leader = False
    cmd = "kubectl exec -i %s -nsso -- sh -c 'echo mntr|nc 127.0.0.1 2181'|grep zk_server_state" % pod
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg and len(ret_msg.split()) != 2:
        msg = "%s 获取角色失败：%s" % (pod, ret_msg)
        logging.error(msg)
        return is_leader

    mode = ret_msg.split()[1]
    # msg = "%s 当前角色：%s" % (pod, mode)
    # logging.info(msg)
    if mode == "leader": is_leader = True
    return is_leader
