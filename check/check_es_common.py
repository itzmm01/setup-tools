#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def get_es_list(app_name=None):
    cmd = "kubectl get es -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'es':
        cmd = "kubectl get es -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的es失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    es_list = ret_msg.split()
    last_msg = "获取es列表: %s" % (es_list)
    logging.info(last_msg)
    return es_list


def get_es_pod_list(es, app_name="es"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (es, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_list = ret_msg.split()
    pod_list_ready = []
    for pod in pod_list:
        cmd1 = "kubectl -n sso get pod %s --no-headers|awk '{if ($3 != \"Running\") print 1; else print 0}'" % pod
        ret_msg1 = os.popen(cmd1).read().strip()
        if ret_msg1 == "1":
            logging.error("%s pod 状态异常" % pod)
            continue
        else:
            pod_list_ready.append(pod)
    return pod_list_ready


def get_es_auth(es):
    cmd = "kubectl get es -nsso --no-headers|grep %s|awk '{print $5}'" % es
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "%s 获取es的auth失败：%s" % (es, cmd)
        logging.error(msg)
        return 1

    return ret_msg


def get_es_user_pass(es):
    cmd = "kubectl -nsso get es %s -ojsonpath=\"{.spec.securityConfig.user}:{.spec.securityConfig.password}\"" % es
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "%s 获取es的用户名/密码失败：%s" % (es, cmd)
        logging.error(msg)
        return 1

    return ret_msg
