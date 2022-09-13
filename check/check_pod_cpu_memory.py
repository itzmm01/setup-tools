#!/usr/bin/python
# -*- coding: UTF-8 -*-
from __future__ import division

import argparse
import re
import sys
import base_comm


def size_conversion(str1):
    var = re.sub(r'\d', "", str1)
    num = re.sub(var, "", str1)
    if var == "Gi" or var == "G":
        return int(num) * 1024
    elif var == "Mi" or var == "M":
        return int(num)
    else:
        return int(num)


def size_conversion_cpu(str1):
    var = re.sub(r'\d', "", str1)
    num = re.sub(var, "", str1)
    if var == "m":
        return int(num)
    else:
        return int(num) * 1000


def args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-pod', dest='pod', type=str, help='pod name', )
    parser.add_argument('-ns', dest='ns', type=str, help='k8s namespace')
    parser.add_argument('-cpu', dest='cpu_threshold', type=int, help='cpu_threshold 80', default="80")
    parser.add_argument('-mem', dest='mem_threshold', type=int, help='mem_threshold 90', default="90")
    return parser.parse_args()


def main(pod_prefix, ns, cpu_threshold, mem_threshold):
    cmd_str1 = """kubectl top pod  -n %s  --containers --no-headers|grep %s|awk '{print $1","$2","$3","$4}'""" % (
        ns, pod_prefix)
    code, pod_info = base_comm.execute_cmd(cmd_str1)
    if code != 0:
        base_comm.log(code, str(cmd_str1))
        base_comm.log(code, str(pod_info))
        return 1
    num = 0
    for line in pod_info:
        container_info = line.split(",")
        jsonpath_str = '{.spec.containers[?(@.name=="%s")].resources.limits.cpu} {.spec.containers[?(@.name=="%s")].resources.limits.memory}' % (
            container_info[1], container_info[1])

        get_limit_cmd = "kubectl get pod %s -n %s -o=jsonpath='%s'" % (container_info[0], ns, jsonpath_str)
        code, limit_info = base_comm.execute_cmd(get_limit_cmd)
        if code != 0:
            base_comm.log(code, str(get_limit_cmd))
            base_comm.log(code, str(limit_info))
            return 1

        for line1 in limit_info:
            limit = line1.split()
            if len(limit) < 2:
                continue
            cpu_use = size_conversion_cpu(container_info[2])
            cpu_limit = size_conversion_cpu(limit[0])

            mem_use = size_conversion(container_info[3])
            mem_limit = size_conversion(limit[1])

            cpu_threshold_cur = round(cpu_use / cpu_limit * 100, 2)
            mem_threshold_cur = round(mem_use / mem_limit * 100, 2)

            if cpu_threshold_cur > cpu_threshold or mem_threshold_cur > mem_threshold:
                base_comm.log(1, "pod: %s 容器:%s cpu使用率: %s内存使用率: %s" % (
                    container_info[0], container_info[1], cpu_threshold_cur, mem_threshold_cur))
                num += 1
            else:
                base_comm.log(0, "pod: %s 容器:%s cpu使用率: %s内存使用率: %s" % (
                    container_info[0], container_info[1], cpu_threshold_cur, mem_threshold_cur))
    return num


if __name__ == '__main__':
    args = args_parser()
    sys.exit(main(args.pod, args.ns, args.cpu_threshold, args.mem_threshold))
