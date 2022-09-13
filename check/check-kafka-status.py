#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm



def args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-ns', dest='namespace', type=str, help='k8s命名空间', )
    parser.add_argument('-name', dest='name', type=str, default="", help='kafka名称 不指定表示获取所有kafka')
    return parser.parse_args()


def check_kafka_lag(ns, info):
    code, metric_port = base_comm.execute_cmd(
        "kubectl -n %s get kafka %s -o jsonpath='{.spec.hostNetworkMetricsPort}'" % (ns, info[0])
    )
    current_cmd = """kubectl -n %s exec svc/kafka-%s -- sh -c "(curl -sS http://localhost:%s/metrics --connect-timeout 5)"|grep consumerlag|egrep -v "__consumer_offsets|TYPE|HELP"|awk '{print $NF}'|sort -nr |head -n1 """ % (
        ns, info[0], metric_port[0])
    code, current_value = base_comm.execute_cmd(current_cmd)

    if float(current_value[0]) <= 500:
        base_comm.log(0, "%s 检查kafka集群lag正常: %s" % (info[0], current_value))
    else:
        base_comm.log(1, "%s 检查kafka集群lag异常: %s" % (info[0], current_value))
        return False


def check_kafka_read(ns, info):
    code, zk_conn = base_comm.execute_cmd(
        "kubectl -n %s get kafka %s -o jsonpath='{.spec.zookeeper.external.connection}'" % (ns, info[0])
    )
    current_cmd = """kubectl -n%s exec -it %s -- bash -c "unset JMX_PORT; unset KAFKA_LOG4J_OPTS;kafka-topics.sh --list --zookeeper %s" """ % (
        ns, info[0], zk_conn[0])
    code, current_value = base_comm.execute_cmd(current_cmd)

    if code == 0:
        base_comm.log(0, "%s 检查kafka读状态正常: %s" % (info[0], current_value))
    else:
        base_comm.log(1, "%s 检查kafka读状态异常: %s" % (info[0], current_value))
        return False


def check_kafka_partition(ns, info):
    code, metric_port = base_comm.execute_cmd(
        "kubectl -n %s get kafka %s -o jsonpath='{.spec.hostNetworkMetricsPort}'" % (ns, info[0])
    )
    current_cmd = """kubectl -n %s exec svc/kafka-%s -- sh -c "(curl -sS http://localhost:%s/metrics --connect-timeout 5)"|grep kafka_controller_kafkacontroller_offlinepartitionscount|egrep -v "TYPE|HELP"|awk '{print $NF}'|sort -nr |head -n1 """ % (
        ns, info[0], metric_port[0])
    code, current_value = base_comm.execute_cmd(current_cmd)

    if float(current_value[0]) <= 1:
        base_comm.log(0, "%s 检查kafka集群没有活跃leader的partition数正常: %s" % (info[0], current_value))
    else:
        base_comm.log(1, "%s 检查kafka集群没有活跃leader的partition数异常: %s" % (info[0], current_value))
        return False


def check_kafka_controller(ns, info):
    code, metric_port = base_comm.execute_cmd(
        "kubectl -n %s get kafka %s -o jsonpath='{.spec.hostNetworkMetricsPort}'" % (ns, info[0])
    )
    current_cmd = """kubectl -n %s exec svc/kafka-%s -- sh -c "(curl -sS http://localhost:%s/metrics --connect-timeout 5)"|grep kafka_controller_kafkacontroller_activecontrollercount|egrep -v "TYPE|HELP"|awk '{print $NF}'|sort -nr |head -n1 """ % (
        ns, info[0], metric_port[0])
    code, current_value = base_comm.execute_cmd(current_cmd)

    if float(current_value[0]) <= 1:
        base_comm.log(0, "%s 检查kafka集群没有活跃leader的Controller正常: %s" % (info[0], current_value))
    else:
        base_comm.log(1, "%s 检查kafka集群没有活跃leader的Controller数异常: %s" % (info[0], current_value))
        return False


def check(ns, cr_name):
    if cr_name == "":
        code, cr_list = base_comm.execute_cmd("kubectl get kafka -n %s --no-headers |awk '{print $1,$6}'" % ns)
    else:
        code, cr_list = base_comm.execute_cmd("kubectl get kafka %s -n %s --no-headers |awk '{print $1,$6}'" % (cr_name, ns))

    num = 0
    if code == 0 and len(cr_list) > 0:
        for cr in cr_list:
            info = cr.split()
            if info[1] != "Ready":
                base_comm.log(1, "获取cr资源状态异常: %s" % cr)
                num += 1
                continue
            num = num + 1 if check_kafka_lag(ns, info) is False else num + 0
            num = num + 1 if check_kafka_partition(ns, info) is False else num + 0
            num = num + 1 if check_kafka_controller(ns, info) is False else num + 0

    else:
        num += 1
        base_comm.log(1, "%s, %s" % (code, str(cr_list)))
    return num


args = args_parser()
if args.namespace is None:
    base_comm.log(1, "namespace is None")
    sys.exit(1)
if check(args.namespace, args.name) != 0:
    sys.exit(1)
