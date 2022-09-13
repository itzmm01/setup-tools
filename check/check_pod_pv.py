#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import subprocess
import sys
import base_comm



def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments')
    parser.add_argument('-pod', dest='pod', type=str, help='pod name', )
    parser.add_argument('-ns', dest='ns', type=str, help='k8s namespace')
    parser.add_argument('-threshold', dest='threshold', type=str, help='threshold 80', default="80")
    args = parser.parse_args()
    return args


def main(pod_prefix, ns, limit):
    pod_list_str = """kubectl -n %s get pod -o go-template --template='{{range .items}}{{$pod_name := .metadata.name}}{{range .status.containerStatuses}}{{$pod_name}}{{" "}}{{.name}}{{"\\n"}}{{end}}{{end}}'|grep %s""" % (
        ns, pod_prefix)
    code, res = base_comm.execute_cmd(pod_list_str)
    if code != 0:
        return
    num = 0
    for pod in res:
        pod_containers = pod.split(" ")
        cmd_str = """kubectl -n {} exec -i {} -c {}  -- df -h|grep -v overlay|awk '{{print $(NF-1)}}'|sort -nr |head -n1""".format(
            ns, pod_containers[0], pod_containers[1])
        code, res = base_comm.execute_cmd(cmd_str)
        if not res: continue
        used = res[0].strip("%")
        if int(used) > int(limit):
            base_comm.log(2, "pod {} pv used: {}".format(pod, used))
            num += 1
    if num > 0:
        sys.exit(1)


if __name__ == '__main__':
    args = args_parser()
    main(args.pod, args.ns, args.threshold)
