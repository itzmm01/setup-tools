#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import base_comm
from check_mariadb_common import get_mariadb_list, get_mariadb_pod_list, get_mariadb_mode

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('-app_name', help='输入需要查找的app名称', type=str, default="mariadb")
args = parser.parse_args()


def check_mariadb_mm_status(app_name="mariadb"):
    mariadb_list = get_mariadb_list(app_name)
    code = 0
    for mariadb in mariadb_list:
        mode = get_mariadb_mode(mariadb=mariadb)
        mariadb_num = len(mariadb)
        msg = "mariadb-MS下名称小于15字符 %s(%s-%s)" % (mariadb, mode, mariadb_num)
        if mode == "MS" and mariadb_num > 15:
            code += 1
            base_comm.log(code, msg)
            continue
        base_comm.log(msg=msg)
    return code


if __name__ == '__main__':
    exit(check_mariadb_mm_status(app_name=args.app_name))
