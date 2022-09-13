#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm


def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments')
    parser.add_argument('-app_name', dest='app_name', type=str, help='si name', default="etcd")
    return parser.parse_args()


def get_etcd_list(app_name=None):
    cmd = "kubectl get etcd -nsso --no-headers|grep -v exporter|awk '{print $1}'"
    if app_name and app_name != 'etcd' and app_name != 'etcd-ks': cmd = "kubectl get etcd -nsso %s --no-headers|grep -v exporter|awk '{print $1}'" % app_name
    # ret_msg = os.popen(cmd).read().lstrip().rstrip()
    code, ret_msg = base_comm.execute_cmd(cmd)
    if code != 0:
        msg = "根据 %s 对应的etcd失败：%s" % (cmd, ret_msg)
        base_comm.log(1, msg)
        return 1

    etcd_list = ret_msg
    last_msg = "获取etcd列表: %s" % (etcd_list)
    base_comm.log(0, last_msg)
    return etcd_list


def get_etcd_pod_list(etcd, app_name="etcd"):
    cmd = "kubectl get pods -owide -nsso -lapp.kubernetes.io/instance=%s,app.kubernetes.io/name=%s " \
          "--no-headers|grep -v exporter" % (etcd, app_name)
    # ret_msg = os.popen(cmd).readlines()
    # if not ret_msg:
    code, ret_msg = base_comm.execute_cmd(cmd)
    if code != 0:
        msg = "根据 %s 对应的pod失败：%s" % (cmd, ret_msg)
        base_comm.log(1, msg)
        return []

    pod_list = list()
    for line in ret_msg:
        pod_name = line.split()[0].strip()
        pod_ip = line.split()[5].strip()
        pod_list.append((pod_name, pod_ip))
    # last_msg = "%s 当前运行的pod列表: %s" % (etcd, pod_list)
    # logging.info(last_msg)
    return pod_list


def check_etcd_health(app_name):
    base_comm.execute_cmd(
        "which etcdctl &>/dev/null || docker cp $(docker ps | grep k8s_etcd_etcd | awk '{print $1}'):/usr/local/bin/etcdctl /usr/local/bin/")
    all_has_leader = 0
    for etcd in get_etcd_list(app_name=app_name):
        pod_list = get_etcd_pod_list(etcd=etcd)
        has_leader = 0
        for pod_name, pod_ip in pod_list:
            cmd = """ETCDCTL_API=3 etcdctl --endpoints="http://%s:2379" endpoint status --write-out=table | egrep "true" | wc -l""" % pod_ip
            code, current = base_comm.execute_cmd(cmd)
            if current[0] == '1':
                base_comm.log(0, "%s, ip为%s, etcd当前的角色是leader" % (pod_name, pod_ip))
                has_leader += 1
            else:
                base_comm.log(0, "%s, ip为%s, etcd当前的角色是follower" % (pod_name, pod_ip))
        if has_leader == 1: all_has_leader += 1
    if all_has_leader == 0: sys.exit(1)


def check_etcd_ks_health():
    base_comm.execute_cmd(
        "which etcdctl &>/dev/null || docker cp $(docker ps | grep k8s_etcd_etcd | awk '{print $1}'):/usr/local/bin/etcdctl /usr/local/bin/")
    code, etcd_list = base_comm.execute_cmd("kubectl get pod -nkube-system -owide | grep etcd")
    has_leader = 0
    for line in etcd_list:
        pod_ip = line.split()[5].strip()
        pod_name = line.split()[0].strip()
        cmd = """ETCDCTL_API=3 etcdctl --endpoints="https://%s:2379" --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint status --write-out=table | egrep "true" | wc -l""" % pod_ip
        code, current = base_comm.execute_cmd(cmd)
        if current[0] == '1':
            base_comm.log(0, "%s, ip为%s, etcd当前的角色是leader" % (pod_name, pod_ip))
            has_leader += 1
        else:
            base_comm.log(0, "%s, ip为%s, etcd当前的角色是follower" % (pod_name, pod_ip))
    if has_leader != 1: sys.exit(1)


def main(app_name="etcd-ks"):
    if app_name == "etcd-ks":
        check_etcd_ks_health()
    else:
        check_etcd_health(app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.app_name)
