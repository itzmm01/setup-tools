#!/usr/bin/python
# -*- coding: UTF-8 -*-
import sys
import base_comm


def get_node_status():
    num = 0
    cmd = "kubectl get node --no-headers|awk '{print $1,$2}'"
    code, res = base_comm.execute_cmd(cmd)
    for node in res:
        node_list = node.split()
        base_comm.log(0, "node-%s: %s" % (node_list[0], node_list[1]))
        if node_list[1] != "Ready":
            num += 1
            get_events = "kubectl describe node %s|sed -n '/^Events/,$p'" % node_list[0]
            code, res = base_comm.execute_cmd(get_events)

            get_conditions = "kubectl describe node %s|sed -n '/^Conditions/,/^\S/p'" % node_list[0]
            code, res1 = base_comm.execute_cmd(get_conditions)
            base_comm.log(2, "\n".join(res1) + "\n" + "\n".join(res))

    sys.exit(num)


get_node_status()
