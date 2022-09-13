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
            "kubectl get pod -nsso | egrep -v 'sentinel|export|dashborad' | grep %s | awk '{print $1}'" % redis)
        for pod in pod_list:
            code, client_conn = base_comm.execute_cmd(
                "kubectl exec -it -n sso %s -- redis-cli %s info |grep connected_clients|"
                "awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (pod, auth_info))
            if not client_conn and len(client_conn) == 0:
                msg = "pod:%s,获取当前连接数失败: %s" % (pod, client_conn)
                base_comm.log(1, msg)
                count += 1
                continue
            client_num = float(client_conn[0])
            code, max_conn = base_comm.execute_cmd(
                "kubectl exec -it -n sso %s -- redis-cli %s info|grep maxclients|"
                "awk -F ':' '{print $NF}'|tr -s '\n'|awk '{print int($0)}'" % (pod, auth_info)
            )
            if not max_conn and len(max_conn) >= 1:
                msg = "pod:%s,获取最大连接数失败: %s" % (pod, max_conn)
                base_comm.log(1, msg)
                count += 1
                continue
            max_num = float(max_conn[0]) * 0.8
            if client_num > max_num:
                base_comm.log(1,
                              "pod:%s,connected_clients:%s,maxclients:%s,客户端连接数超过最大连接数百分之80" % (
                              pod, client_conn, max_conn)
                              )
                count += 1
            else:
                base_comm.log(0, "pod:%s,connected_clients:%s,maxclients:%s" % (pod, client_conn, max_conn))
    if count != 0:
        sys.exit(1)


def main(app_name="redis"):
    check_redis_conn(app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.app_name)
