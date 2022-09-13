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
    code, redis_list = base_comm.execute_cmd("kubectl -n sso get redis|grep -v NAME| grep %s |awk '{print $1}'" % app_name)
    count = 0
    for redis in redis_list:
        auth_info = base_comm.get_redis_auth(redis)
        code, pod_list = base_comm.execute_cmd(
            "kubectl get pod -nsso | egrep -v 'sentinel|export|dashborad' | grep %s | awk '{print $1}'" % redis)
        for pod in pod_list:
            cmd = "kubectl exec -i -n sso %s -- redis-cli %s ping" % (pod, auth_info)
            code, result = base_comm.execute_cmd(cmd)
            if result[0] == 'PONG':
                base_comm.log(0, "pod:%s,用户认证正常: %s" % (pod, auth_info))
            else:
                base_comm.log(1, cmd)
                base_comm.log(1, "pod:%s,用户认证异常: %s" % (pod, auth_info))
                count += 1
    if count != 0:
        sys.exit(1)


def main(app_name="redis"):
    check_redis_conn(app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.app_name)
