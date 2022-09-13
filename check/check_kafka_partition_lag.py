#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
from check_kafka_common import get_kafka_list, get_kafka_pod_list, get_kafka_zk_conn, get_kafka_metric_port

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app所在的机器', type=str)
parser.add_argument('--threshold', help='kafka的lag的阈值', type=int, default=50)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def kafka_partition_lag(app_name=None, threshold=50):
    kafka_list = get_kafka_list(app_name)
    for kafka in kafka_list:
        metric_port = get_kafka_metric_port(kafka=kafka)
        pod_list = get_kafka_pod_list(kafka)
        for pod in pod_list:
            cmd = "kubectl -nsso exec -i svc/kafka-%s -- sh -c '(curl -sS http://localhost:%s/metrics --connect-timeout 5)'" \
                  "|grep consumerlag|egrep -v \"__consumer_offsets|TYPE|HELP\"" % (kafka, metric_port)
            logging.info(cmd)
            ret_msg = os.popen(cmd).readlines()
            # logging.info(ret_msg)
            if not ret_msg:
                msg = "%s 集群获取topic的lag失败：%s" % (pod, ret_msg)
                logging.error(msg)
                return 1

            for line in ret_msg:
                if not line and len(line.split()) != 2:
                    continue

                topic = line.split()[0].lstrip().rstrip()
                lag = line.split()[1].lstrip().rstrip()
                if float(lag) >= threshold:
                    msg = "%s 的topic %s的lag过大: %s" % (pod, topic, lag)
                    logging.error(msg)
                    return 1

        msg = "%s 的所有topic的lag低于%s" % (kafka, threshold)
        logging.info(msg)


if __name__ == '__main__':
    exit(kafka_partition_lag(app_name=args.app_name, threshold=args.threshold))
