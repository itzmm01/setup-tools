#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_kafka_common import get_kafka_list, get_kafka_pod_list, get_kafka_zk_conn, get_kafka_metric_port

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
parser.add_argument('--threshold', help='kafka的没有活跃controller的阈值', type=int, default=1)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def kafka_partition_controller(app_name=None, threshold=1):
    kafka_list = get_kafka_list(app_name)
    for kafka in kafka_list:
        metric_port = get_kafka_metric_port(kafka=kafka)
        pod_list = get_kafka_pod_list(kafka)
        for pod in pod_list:
            cmd = "kubectl -nsso exec -i svc/kafka-%s -- sh -c '(curl -sS http://localhost:%s/metrics --connect-timeout 5)'" \
                  "|grep kafka_controller_kafkacontroller_activecontrollercount|egrep -v \"__consumer_offsets|TYPE|HELP\"""" % (
                      kafka, metric_port)
            logging.info(cmd)
            ret_msg = os.popen(cmd).readlines()
            if not ret_msg:
                msg = "%s 集群获取parition的controller失败：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1

            for line in ret_msg:
                if not line and len(line.split()) != 2:
                    continue

                controller = line.split()[0].lstrip().rstrip()
                count = line.split()[1].lstrip().rstrip()
                if float(count) != float(threshold):
                    msg = "%s 的topic %s 都没有活跃的controller: %s" % (pod, controller, count)
                    logging.error(msg)
                    return 1

        msg = "%s 的所有topic的partition都含有活跃的controller" % (kafka)
        logging.info(msg)


if __name__ == '__main__':
    exit(kafka_partition_controller(app_name=args.app_name, threshold=args.threshold))
