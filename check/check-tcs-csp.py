#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import json

import base_comm


def args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', dest='item', type=str, help='检查项: bucket_stat', )
    return parser.parse_args()


def check_version():
    code, tcs_version = base_comm.execute_cmd("cat /data/tce_dc/tcs/version")
    if code != 0:
        base_comm.log(msg="cat /data/tce_dc/tcs/version", code=1)
        base_comm.log(msg="no get tcs version", code=1)
        return False
    else:
        if 'TCS2.3.' in '\n'.join(tcs_version):
            return True
        else:
            return False


def bucket_stat():
    bucket_str_cmd = "radosgw-admin -c /data/cos/ceph.DATAACCESS.conf bucket stats"
    bucket_dict = dict
    if check_version():
        code, res = base_comm.pod_state("csp-pod-rgw", "tcs-system")
        if code == 0:
            k8s_cmd = "kubectl -n tcs-system exec -it csp-pod-rgw-1 -- sh -c '%s'" % bucket_str_cmd
            print(k8s_cmd)
            code, bucket_info = base_comm.execute_cmd(
                k8s_cmd
            )
            bucket_dict = json.loads("\n".join(bucket_info))
    else:
        code, bucket_info = base_comm.execute_cmd(
            bucket_str_cmd
        )
        bucket_dict = json.loads(bucket_info)

    for bucket in bucket_dict:
        bucket_name = bucket["bucket"]
        bucket_max_size = bucket["bucket_quota"]["max_objects"]
        bucket_max_obj = bucket["bucket_quota"]["max_size_kb"]

        for k, v in bucket["usage"].items():
            size_kb = v["size_kb"]
            num_objects = v["num_objects"]
            msg = "%s-%s max_size: %s, use_size: %s max_obj: %s, use_max: %s" % (
                bucket_name, k, bucket_max_size, size_kb, bucket_max_obj, num_objects
            )
            print(msg)
            if size_kb != 0 and bucket_max_size != 0:
                print(round(size_kb / bucket_max_size, 3))
            if num_objects != 0 and bucket_max_obj != 0:
                print(round(num_objects / bucket_max_obj, 3))


args = args_parser()

if args.item == "bucket_stat":
    bucket_stat()
else:
    base_comm.log(1, "no support %s" % args.item)
