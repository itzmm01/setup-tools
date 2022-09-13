#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse
import json

'''
1、参数--metrics 'node_cpu_usage{node="172.27.16.244"}'
2、执行curl -G 'http://172.27.16.194:30350/prometheus/api/v1/query?query=node_cpu_usage\{node="172.27.16.244"\}&timeout=5'
'''

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--metrics', help='判断能否通过prometheus获取指标', type=str, default='node_cpu_usage{}')
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def check_infrastore_metrics(metrics='node_cpu_usage{}'):
    cmd = "kubectl get nodes -A --no-headers|grep ' Ready'|awk '{print $1}'|head -n1"
    node = os.popen(cmd).read().lstrip().rstrip()
    cmd = "kubectl get svc -A|grep 11130|awk '{print $(NF-1)}'|awk -F ':' '{print $2}'|awk -F '/' '{print $1}'"
    port = os.popen(cmd).read().lstrip().rstrip()
    prom_api = "'" + "http://%s:%s/prometheus/api/v1/query" % (node, port)
    metrics = metrics.replace("{", "\{").replace("}", "\}")
    query = "?query=%s&timeout=5" % metrics + "'"
    url = "curl -G " + prom_api + query
    logging.info(url)
    ret_msg = json.loads(os.popen(url).read())
    logging.info(ret_msg)
    result = ret_msg.get("data").get("result")
    last_msg = "云哨查询数据正常,metrics为: %s" % (metrics)
    if not result:
        msg = "云哨查询数据失败,metrics为: %s" % (metrics)
        logging.error(msg)
        return 1
    logging.info(last_msg)
    return 0


if __name__ == '__main__':
    exit(check_infrastore_metrics(args.metrics))
