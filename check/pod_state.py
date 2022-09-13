#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm


def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments')
    parser.add_argument('-app_name', dest='app_name', type=str, help='容器 app_name', )
    parser.add_argument('-namespace', dest='namespace', type=str, help='k8s namespace')
    parser.add_argument('-cmd_list', dest='cmd_list', type=str, help='容器中执行的命令', default=None)
    parser.add_argument('-pod_limit', dest='pod_limit', type=str, help='同 app_name pod 数量限制, 默认巡检所有', default=None)
    parser.add_argument('-age', dest='age', type=str,
                        help='容器存活时长阈值，小于这个阈值就发出告警，默认做判断，1h，1d，10d，单位只有h和d', default=None)
    parser.add_argument('-is_ha', dest='is_ha', type=bool, help='是否是高可用的容器，只要保证有running 1/1就可以了', default=False)
    parser.add_argument('-exec_args', dest='exec_args', type=str,
                        help='用于exec 其他参数 kubectl exec -n {namespace} {pod_name} {exec_args}-- {cmd_dict["cmd"]}',
                        default=None)
    parser.add_argument('-expr', dest='expr', type=str, help='匹配表达式(result是占位符表示命令输出结果): result == 1 ', default="")
    return parser.parse_args()


args = args_parser()
if args.app_name is None or args.namespace is None:
    base_comm.log(2, "app_name or namespace is None")
    sys.exit(1)
code, msg = base_comm.pod_state(
    args.app_name, args.namespace, args.expr, args.cmd_list, args.pod_limit, args.age, args.is_ha,
    args.exec_args,
)
if code != 0:
    # logging.info(msg)
    sys.exit(1)
