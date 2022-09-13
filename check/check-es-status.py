#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import json
import subprocess
import sys
import logging

LOG_FORMAT = "%(asctime)s    [%(levelname)s]  %(lineno)d:%(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def execute_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    if p.returncode == 0:
        result_list = [cmd_res_compatible(i) for i in p.stdout.readlines()]
        return p.returncode, result_list
    else:
        return p.returncode, p.stderr.readlines()


def cmd_res_compatible(line):
    if sys.version.split('.')[0] == "2":
        return line.strip("\n")
    else:
        return line.decode("utf-8").strip("\n")


def args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-ns', dest='namespace', type=str, help='k8s命名空间', )
    parser.add_argument('-name', dest='name', type=str, default="", help='es名称 不指定表示获取所有es')
    return parser.parse_args()


def check_cluster_status(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + " -H 'Content-Type: application/json' " \
                                     "'http://localhost:9200/_cluster/health?pretty' -s "
    check_cluster = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, cluster_status = execute_cmd(check_cluster)
    if code != 0:
        logging.error("%s 获取es集群状态失败" % es_name)
        return False
    cluster_status_str = "\n".join(cluster_status)
    try:
        status = json.loads(cluster_status_str).get("status")
    except Exception as e:
        logging.error("%s es集群状态错误: " % es_name + str(cluster_status) + str(e))
        status = "None"
    if status != "green":
        logging.error("%s es集群状态: " % es_name + str(status))
        return False
    else:
        logging.info("%s es集群状态: " % es_name + str(status))
        return True


def check_index(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + "  -H 'Content-Type: application/json' " \
                                     "'http://localhost:9200/_cat/indices?v&health=yellow' -s "
    check_index_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, cluster_status = execute_cmd(check_index_cmd)
    if code != 0:
        logging.error("%s 获取es索引信息失败: " % es_name + str(cluster_status))
        return False
    if len(cluster_status) > 1:
        logging.error("%s es索引yellow状态: " % es_name + str(cluster_status))
        return False
    else:
        logging.info("%s es索引正常" % es_name)


def check_node_num(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + " http://localhost:9200/_cluster/health?pretty --connect-timeout 5|grep " \
                                     "status |grep green|wc -l "
    check_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, result = execute_cmd(check_cmd)
    if code != 0:
        logging.error(check_cmd)
        logging.error("%s 获取es节点数量信息失败: " % es_name + str(result))
        return False
    if result[0] == "1":
        logging.info("%s es节点数量正常 %s" % (es_name, result[0]))
    else:
        logging.error("%s es节点数量异常 %s" % (es_name, result[0]))
        return False


def check_shard(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + "http://localhost:9200/_cluster/health?pretty --connect-timeout 5|grep " \
                                     "active_shards_percent_as_number"
    check_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, result = execute_cmd(check_cmd)
    if code != 0:
        logging.error(check_cmd)
        logging.error("%s 获取es节点shard信息失败: " % es_name + str(result))
        return False
    shard_num = result[0].split(":")
    if float(shard_num[1].strip(",")) == float(100):
        logging.info("%s 检测shard完整数是不是100 %s" % (es_name, shard_num))
    else:
        logging.error("%s 检测shard完整数是不是100 %s" % (es_name, shard_num))
        return False


def check_active_shard(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + " http://localhost:9200/_cluster/health?pretty --connect-timeout 5|grep " \
                                     "active_primary_shards"
    check_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, result = execute_cmd(check_cmd)
    if code != 0:
        logging.error(check_cmd)
        logging.error("%s 获取es节点shard信息失败: " % es_name + str(result))
        return False

    shard_num = result[0].split(":")
    if float(shard_num[1].strip(",")) < float(2500):
        logging.info("%s 检测active_primary_shards是否大于2500 %s" % (es_name, shard_num))
    else:
        logging.error("%s 检测active_primary_shards是否大于2500 %s" % (es_name, shard_num))
        return False


def check_node_disk(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + " http://localhost:9200/_cat/allocation?v --connect-timeout 5|grep " \
                                     "-v disk |awk '{print \$6}'|sort -nr |head -n1"
    check_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, result = execute_cmd(check_cmd)
    if code != 0:
        logging.error(check_cmd)
        logging.error("%s 获取es节点shard信息失败: " % es_name + str(result))
        return False
    if float(result[0]) < float(70):
        logging.info("%s 检测es集群的节点磁盘使用率 %s" % (es_name, result))
    else:
        logging.error("%s 检测es集群的节点磁盘使用率 %s" % (es_name, result))
        return False


def check_only_read(ns, curl_str, pod_list, es_name):
    curl_cluster_status = curl_str + " '127.0.0.1:9200/_cluster/settings?pretty/&include_defaults=true" \
                                     "/&flat_settings=true' --connect-timeout 5| grep read_only|grep true|wc -l"
    check_cmd = "kubectl -n %s exec -i %s -- bash -c \"%s\"" % (ns, pod_list[0], curl_cluster_status)
    code, result = execute_cmd(check_cmd)
    if code != 0:
        logging.error(check_cmd)
        logging.error("%s 获取es节点shard信息失败: " % es_name + str(result))
        return False
    if float(result[0]) == float(0):
        logging.info("%s 检测es集群的节点磁盘使用率 %s" % (es_name, result))
    else:
        logging.error("%s 检测es集群的节点磁盘使用率 %s" % (es_name, result))
        return False


def check_es(ns, es):
    if es == "":
        code, es_list = execute_cmd("kubectl get es -n %s --no-headers |awk '{print $1,$6}'" % ns)
    else:
        code, es_list = execute_cmd("kubectl get es %s -n %s --no-headers |awk '{print $1,$6}'" % (es, ns))

    num = 0
    if code == 0 and len(es_list) > 0:
        for es_info_str in es_list:
            es_info = es_info_str.split()
            if es_info[1] != "Ready":
                logging.error("获取es资源异常: %s" % es_info)
                continue

            es_auth_info_cmd = 'kubectl -n %s get es %s -ojsonpath="{.spec.securityConfig.user} {.spec.securityConfig.password}"' % (
                ns, es_info[0]
            )
            code, es_auth_info = execute_cmd(es_auth_info_cmd)
            if code != 0:
                logging.error(str(es_auth_info))
                continue
            es_auth = es_auth_info[0].split()
            code, pod_list = execute_cmd(
                "kubectl -n %s get pod |grep %s |grep -v export|awk '{print $1}'" % (ns, es_info[0]))
            if code != 0:
                logging.error("获取es pod异常: %s" % str(pod_list))
                continue
            if len(es_auth) == 2:
                curl_str = "curl -u %s:'%s' -sS " % (es_auth[0], es_auth[1])
            else:
                curl_str = "curl -sS "
            num = num + 1 if check_cluster_status(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_index(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_node_num(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_shard(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_active_shard(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_node_disk(ns, curl_str, pod_list, es_info[0]) is False else num + 0
            num = num + 1 if check_only_read(ns, curl_str, pod_list, es_info[0]) is False else num + 0

    else:
        logging.error("%s, %s" % (code, str(es_list)))
        num = num + 1
    return num


args = args_parser()
if args.namespace is None:
    logging.error("namespace is None")
    sys.exit(1)
if check_es(args.namespace, args.name) != 0:
    sys.exit(1)
