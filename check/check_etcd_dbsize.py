#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm


def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments')
    parser.add_argument('-app_name', dest='app_name', type=str, help='si name')
    parser.add_argument('-threshold', dest='threshold', type=str, help='dbsize threshold unit G')
    return parser.parse_args()


def check_etcd_dbsize(threshold, app_name):
    base_comm.execute_cmd(
        "which etcdctl &>/dev/null || docker cp $(docker ps | grep k8s_etcd_etcd | awk '{print $1}'):/usr/local/bin/etcdctl /usr/local/bin/")
    if app_name != "etcd-ks":
        code, ip_list = base_comm.execute_cmd("kubectl get pod -nsso -owide | grep %s | awk '{print $6}'" % app_name)
    else:
        code, ip_list = base_comm.execute_cmd("kubectl get pod -nkube-system -owide | grep etcd | awk '{print $6}'")
    tmp = 0
    count = 0
    for pod_ip in ip_list:
        if app_name != "etcd-ks":
            cmd = """ETCDCTL_API=3 etcdctl --endpoints="http://%s:2379" endpoint status --write-out=table | awk '/http/ {print $8,$9}'""" % pod_ip
        else:
            cmd = """ETCDCTL_API=3 etcdctl --endpoints="https://%s:2379" --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint status --write-out=table | awk '/http/ {print $8,$9}'""" % pod_ip
        code, current = base_comm.execute_cmd(cmd)
        if len(current) == 0:
            continue
        size = float(current[0][:-3])
        unit = current[0][-2:]
        if unit == "MB":
            tmp = size * 1024 * 1024
        elif unit == "GB":
            tmp = size * 1024 * 1024 * 1024
        else:
            base_comm.log(1, "请检查ip为%s的etcd运行情况" % pod_ip)
        thresholdTmp = float(threshold) * 1073741824
        if tmp > thresholdTmp:
            base_comm.log(1, "ip为%s的etcd数据量超过%sG,当前数据量为: %s" % (pod_ip, threshold, current))
            count += 1
        else:
            base_comm.log(0, "ip为%s的etcd数据量未超过%sG,当前数据量为: %s" % (pod_ip, threshold, current))
    if count > 0:
        sys.exit(1)


def main(threshold, app_name="etcd-ks"):
    check_etcd_dbsize(threshold, app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.threshold, args.app_name)
