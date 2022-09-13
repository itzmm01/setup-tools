#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import getpass
import base_comm
import sys

sudo_default = "/usr/bin/python, /usr/bin/rpm, /usr/bin/python2, /usr/bin/python3, /usr/bin/docker, /usr/bin/cp," \
               " /usr/bin/cat, /usr/bin/chmod +rx -R /etc/kubernetes, /usr/sbin/ambari-agent, /usr/bin/ceph," \
               " /usr/bin/radosgw-admin, /usr/bin/ceph, /usr/bin/dpkg"


def args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-r', dest='req', default=sudo_default, type=str, help='需要的sudo权限')
    return parser.parse_args()


user_name = getpass.getuser()
if user_name == "root":
    sys.exit(0)
num = 0
args = args_parser()
sudo_str = args.req
cmd = "echo '123'|sudo -S -l -U %s |grep '%s'" % (user_name, sudo_str)
code, res = base_comm.execute_cmd(cmd)
if code != 0:
    base_comm.log(2, "please use root exec: echo '%s    ALL=(ALL)    NOPASSWD: %s' >> /etc/sudoers.d/%s" % (
        user_name, sudo_str, user_name))
    sys.exit(1)
else:
    sys.exit(0)
