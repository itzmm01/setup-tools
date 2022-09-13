#!/usr/bin/python
# -*- coding: UTF-8 -*-
import sys
import base_comm


def check_sentinel_conn():
    count = 0
    code, pod_list = base_comm.execute_cmd(
        "kubectl -n sso get pod|grep -v NAME| grep 'global-redis-sentinel' |awk '{print $1}'")
    for pod in pod_list:
        cmd = "kubectl exec -i -n sso %s -- redis-cli -p 26379 auth tcns@redis" % (pod)
        code, result = base_comm.execute_cmd(cmd)
        if result[0] == 'OK':
            base_comm.log(0, "pod:%s,用户认证正常" % (pod))
        else:
            base_comm.log(1, "pod:%s,用户认证异常" % (pod))
            count += 1
    if count != 0:
        sys.exit(1)


def main():
    check_sentinel_conn()


if __name__ == '__main__':
    main()
