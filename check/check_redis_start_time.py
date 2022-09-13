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
            cmd = "kubectl exec -it -n sso %s -- redis-cli %s info |grep uptime_in_seconds|" \
                  "awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (pod, auth_info)

            code, result = base_comm.execute_cmd(cmd)
            if not result and len(result) == 0:
                msg = "pod:%s,获取启动时间失败: %s" % (pod, result)
                base_comm.log(1, msg)
                count += 1
                continue
            if result[0] < 60:
                base_comm.log(1, "pod:%s,uptime_in_seconds:%s,启动时间小于60s" % (pod, result))
                count += 1
            else:
                base_comm.log(0, "pod:%s,uptime_in_seconds:%s,启动时间大于60s" % (pod, result))

    if count != 0:
        sys.exit(1)


def main(app_name="redis"):
    check_redis_conn(app_name)


if __name__ == '__main__':
    args = args_parser()
    main(args.app_name)
