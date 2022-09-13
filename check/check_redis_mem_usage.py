#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm


def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments')
    parser.add_argument('-app_name', dest='app_name', type=str, help='si name')
    return parser.parse_args()


def check_redis_conn(app_name):
    code, redis_list = base_comm.execute_cmd(
        "kubectl -n sso get redis|grep -v NAME| grep %s |awk '{print $1}'" % app_name)
    count = 0
    for redis in redis_list:
        auth_info = base_comm.get_redis_auth(redis)
        code, pod_list = base_comm.execute_cmd(
            "kubectl get pod -nsso | egrep -v 'sentinel|export|dashborad' | grep %s | awk '{print $1}'" % (redis))
        for pod in pod_list:
            code, used_mem = base_comm.execute_cmd(
                "kubectl exec -it -n sso %s -- redis-cli %s info |grep 'used_memory:'"
                " |awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (pod, auth_info))
            if not used_mem and len(used_mem) == 0:
                msg = "pod:%s,获取当前使用内存失败: %s" % (pod, used_mem)
                base_comm.log(1, msg)
                count += 1
                continue
            code, max_mem = base_comm.execute_cmd(
                "kubectl exec -it -n sso %s -- redis-cli %s info |grep 'maxmemory:' "
                "|awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (pod, auth_info))
            if not max_mem and len(max_mem) >= 1:
                msg = "pod:%s,获取最大使用内存失败: %s" % (pod, max_mem)
                base_comm.log(1, msg)
                count += 1
                continue
            if int(max_mem[0]) == 0:
                msg = "pod:%s,没有设置最大使用内存: %s" % (pod, max_mem)
                base_comm.log(1, msg)
                continue
            result = float(used_mem[0]) / float(max_mem[0])
            if result > 0.8:
                base_comm.log(1,
                              "pod:%s,used_memory:%s,maxmemory:%s,usage:%s,内存使用超出最大内存百分之80" % (
                                  pod, used_mem, max_mem, result))
                count += 1
            else:
                base_comm.log(0, "pod:%s,used_memory:%s,maxmemory:%s,usage:%s" % (pod, used_mem, max_mem, result))
    if count != 0:
        sys.exit(1)


def main(app_name="redis"):
    check_redis_conn(app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.app_name)
