#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_kafka_common import get_kafka_list, get_kafka_pod_list, get_kafka_zk_conn

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def kafka_read_status(app_name=None):
    kafka_list = get_kafka_list(app_name)
    for kafka in kafka_list:
        zk_conn = get_kafka_zk_conn(kafka=kafka)
        pod_list = get_kafka_pod_list(kafka)
        for pod in pod_list:
            cmd = "kubectl -nsso exec -i %s -- bash -c 'unset JMX_PORT; unset KAFKA_LOG4J_OPTS;" \
                  "kafka-topics.sh --list --zookeeper %s'" % (pod, zk_conn)
            logging.info(cmd)
            ret_msg = os.popen(cmd).read().lstrip().rstrip()
            # logging.info(ret_msg)
            if not ret_msg:
                msg = "%s 集群读失败：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1

            msg = "%s 集群读状态成功" % (pod)
            logging.info(msg)


if __name__ == '__main__':
    exit(kafka_read_status(app_name=args.app_name))
