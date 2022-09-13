#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def get_kafka_list(app_name=None):
    cmd = "kubectl get kafka -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'kafka': cmd = "kubectl get kafka -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "根据 %s 对应的kafka失败：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    kafka_list = ret_msg.split()
    last_msg = "获取kafka列表: %s" % (kafka_list)
    logging.info(last_msg)
    return kafka_list


def get_kafka_pod_list(kafka, app_name="kafka"):
    cmd = "kubectl get pods -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter|awk '{print $1}'" % (kafka, app_name)
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "获取kafka pod失败 %s：%s" % (cmd, ret_msg)
        logging.error(msg)
        return 1

    pod_ready = []
    for pod in ret_msg.split():
        cmd1 = "kubectl -n sso get pod %s --no-headers|awk '{if ($3 != \"Running\") print 1; else print 0}'" % pod
        ret_msg1 = os.popen(cmd1).read().strip()
        if ret_msg1 == "1":
            logging.error("%s pod 状态异常" % pod)
            continue
        else:
            pod_ready.append(pod)
    return pod_ready


def get_kafka_zk_conn(kafka):
    cmd = "kubectl -n sso get kafka %s -o jsonpath='{.spec.zookeeper.external.connection}'" % kafka
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "%s 获取Kafka的zk_conn失败：%s" % (kafka, cmd)
        logging.error(msg)
        return 1

    return ret_msg


def get_kafka_metric_port(kafka):
    cmd = "kubectl -n sso get kafka %s -o jsonpath='{.spec.hostNetworkMetricsPort}'" % kafka
    ret_msg = os.popen(cmd).read().lstrip().rstrip()
    if not ret_msg:
        msg = "%s 获取Kafka的metric端口失败：%s" % (kafka, cmd)
        logging.error(msg)
        return 1

    return ret_msg
