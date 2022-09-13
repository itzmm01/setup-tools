#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import sys
import base_comm
import json


def size_compare(bucket, usage_size, bucket_name):
    quota_size = bucket["bucket_quota"]["max_size_kb"]
    if int(usage_size) == 0:
        size_GB = 0
        utili_rate = 0
    else:
        size_GB = round(float(usage_size / 1024 / 1024), 3)
        if quota_size == 0:
            utili_rate = 0
        else:
            utili_rate = round(float(usage_size * 100) / float(quota_size), 3)
    if quota_size != 0:
        quota_size = round(float(quota_size / 1024 / 1024), 3)
    return size_GB, quota_size, utili_rate


def size_object(bucket, usage_object, bucket_name):
    quota_obj = bucket["bucket_quota"]["max_objects"]
    if int(usage_object) == 0:
        obj_num = 0
        utili_rate = 0
    else:
        obj_num = usage_object
        if quota_obj == 0:
            utili_rate = 0
        else:
            utili_rate = round(float(usage_object * 100) / float(quota_obj), 3)
    return obj_num, quota_obj, utili_rate

def get_user_info(version, bucket_all_info):
    get_all_user_cmd = "/usr/bin/radosgw-admin -c /data/cos/$(ls /data/cos |head -1) user list"
    if version != "212":
        get_all_user_cmd = "kubectl exec -i -n tcs-system   csp-pod-rgw-0 -- sh -c '%s'" % get_all_user_cmd
    code, res =  base_comm.execute_cmd(get_all_user_cmd)
    all_user = json.loads("\n".join(res))
    num = 0
    for user in all_user:
        if user == "admin":
            continue
        get_user_quota_cmd = "/usr/bin/radosgw-admin -c /data/cos/$(ls /data/cos |head -1) user info --uid=" + user
        get_user_info_cmd = "/usr/bin/radosgw-admin -c /data/cos/$(ls /data/cos |head -1) user stats --uid=" + user
        if version != "212":
            get_user_quota_cmd = "kubectl exec -i -n tcs-system  csp-pod-rgw-0 -- sh -c '%s' "  % get_user_quota_cmd
            get_user_info_cmd = "kubectl exec -i -n tcs-system  csp-pod-rgw-0 -- sh -c '%s' "  % get_user_info_cmd
        code1, res1 =  base_comm.execute_cmd(get_user_quota_cmd)
        code2, res2 =  base_comm.execute_cmd(get_user_info_cmd)
        user_quota = json.loads("\n".join(res1))["user_quota"]
        user_stats = json.loads("\n".join(res2))["stats"]
        total_gb = user_stats["total_bytes"] / 1024 / 1024 /1024
        quota_gb = user_quota["max_size"] / 1024 / 1024 / 1024
        if user_quota["max_objects"] == -1:
            user_used_obj = 0
        else:
            user_used_obj = round(float(user_stats["total_entries"]) / float(user_quota["max_objects"]) * 100, 2)
            
        if user_quota["max_size"] == -1:
            user_used = 0
        else:
            user_used = round(float(user_stats["total_bytes"])/float(user_quota['max_size']) * 100, 2)
        
        msg = "用户: %s 大小: %sG, 使用率: %s, 配额: %sG , objects: %s, 使用率: %s, 配额: %s" % (user, total_gb, user_used, quota_gb, user_stats["total_entries"], user_used_obj, user_quota["max_objects"])
        if user_used > 80 or user_used_obj > 80 :
            num += 1
            base_comm.log(1, msg)
            for i in bucket_all_info.get(user):
                msg1 = "bucket: %s 大小: %sG 使用率: %s object: %s 使用率: %s" % (i["name"], i["size"][0],i["size"][2], i["objects"][0], i["objects"][2])
                if i["size"][2] > 80 or i["objects"][2] > 80:
                    base_comm.log(1, msg1)
                else:
                    base_comm.log(0, msg1)
        else:
            base_comm.log(0, msg)
            for i in bucket_all_info.get(user):
                msg1 = "bucket: %s 大小: %sG 使用率: %s object: %s 使用率: %s" % (i["name"], i["size"][0],i["size"][2], i["objects"][0], i["objects"][2])
                if i["size"][2] > 80 or i["objects"][2] > 80:
                    base_comm.log(1, msg1)
                else:
                    base_comm.log(0, msg1)
                    
    return num
 

def get_bucket_info(version="230", threshold=80):
    if version == "212":
        cmd = '/usr/bin/radosgw-admin -c /data/cos/ceph.DATAACCESS.conf bucket stats'
    else:
        cmd = 'kubectl exec -i -n tcs-system   csp-pod-rgw-0 -- sh -c "/usr/bin/radosgw-admin -c ' \
              '/data/cos/ceph.DATAACCESS.conf bucket stats " '

    code, res = base_comm.execute_cmd(cmd)
    if code != 0:
        base_comm.log(code, "\n".join(res))
        sys.exit(1)
    bucket_info_list = json.loads("\n".join(res))
    bucket_all_info = {}
    for bucket in bucket_info_list:
        bucket_user = bucket["owner"]
        bucket_name = bucket["bucket"]
        
        bucket_tmp = {"name": bucket_name}
        if bucket["usage"] == {}:
            bucket_tmp["size"] = [0, 0, 0]
            bucket_tmp["objects"] = [0, 0, 0]
        else:
            if bucket["usage"].get("rgw.main"):
                usage_size = bucket["usage"]["rgw.main"]["size_kb"]
                usage_object = bucket["usage"]["rgw.main"]["num_objects"]
                size_GB, size_quota, size_utili_rate = size_compare(bucket, usage_size, bucket_name)
                obj_num, obj_quota, obj_utili_rate = size_object(bucket, usage_object, bucket_name)
                
                bucket_tmp["size"] = [size_GB, size_quota, size_utili_rate]
                bucket_tmp["objects"] = [obj_num, obj_quota, obj_utili_rate]
            else:
                bucket_tmp["size"] = [0, 0, 0]
                bucket_tmp["objects"] = [0, 0, 0]
        if bucket_all_info.get(bucket_user):
            bucket_all_info.get(bucket_user).append(bucket_tmp)
        else:
            bucket_all_info[bucket_user] = [bucket_tmp]
    sys.exit(get_user_info(version, bucket_all_info))


parser = argparse.ArgumentParser()
parser.add_argument("-version", help='tcs version', type=str, default="230")
parser.add_argument("-threshold", help='threshold', type=int, default=80)
args = parser.parse_args()
get_bucket_info(args.version, args.threshold)
