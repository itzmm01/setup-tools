#!/usr/bin/python
# -*- coding: UTF-8 -*-
import sys
import base_comm


def check_sentinel_conn():
    count = 0
    code, pod_list = base_comm.execute_cmd(
        "kubectl -n sso get pod|grep -v NAME| grep 'global-redis-sentinel' |awk '{print $1}'")
    for pod in pod_list:
        code, client_conn = base_comm.execute_cmd(
            "kubectl exec -i -n sso %s -- redis-cli -a tcns@redis -p 26379 info 2>/dev/null |grep connected_clients|awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (
                pod))
        code, max_conn = base_comm.execute_cmd(
            "kubectl exec -i -n sso %s -- redis-cli -a tcns@redis -p 26379 info 2>/dev/null |grep maxclients|awk -F ':' '{print $NF}'| tr -s '\n'| awk '{print int($0)}'" % (
                pod))
        client_num = float(client_conn[0])
        max_num = float(max_conn[0]) * 0.8
        if client_num > max_num:
            base_comm.log(1, "pod:%s,connected_clients:%s,maxclients:%s,客户端连接数超过最大连接数百分之80" % (pod, client_conn, max_conn))
            count += 1
        else:
            base_comm.log(0, "pod:%s,connected_clients:%s,maxclients:%s" % (pod, client_conn, max_conn))
    if count != 0:
        sys.exit(1)


def main():
    check_sentinel_conn()


if __name__ == '__main__':
    main()
