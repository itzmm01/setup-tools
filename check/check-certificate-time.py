#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import time
import base_comm


def get_cert_time(cert_dir):
    cmd = """for i in `find {} -type f |egrep '.crt$|.pem$'`;do  max=$(date +%s -d "`openssl x509 -in $i -noout \
-dates 2> /dev/null|grep After|awk -F 'notAfter=' '{{print $2}}'`");  echo $i $max ;done""".format(cert_dir)
    code, result = base_comm.execute_cmd(cmd)
    if code != 0:
        base_comm.log(code, result)
        return 1
    for i in result:
        info = i.split()
        expire_day = (int(info[1]) - time.time()) / (60 * 60 * 24)
        msg = "%s expires in %s days" % (info[0], expire_day)
        if expire_day > 45:
            base_comm.log(msg=msg)
        else:
            base_comm.log(code=1, msg=msg)


parser = argparse.ArgumentParser()
parser.add_argument("-d", dest="cert_dir", help='指定目录', type=str, default="/etc")
args = parser.parse_args()
get_cert_time(args.cert_dir)
