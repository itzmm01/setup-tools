#!/usr/bin/python
# -*- coding: UTF-8 -*-
import base_comm


def get_svc():
    cmd = """kubectl get svc -n infrastore-metric   infrastore-metric-scraper-external --no-headers|awk '{if(\
    $2=="LoadBalancer" && $4 !="<none>") {print "OK: "$2,$4}else {print "ERROR: "$2,$4}}' """
    code, res = base_comm.execute_cmd(cmd)
    if code != 0:
        base_comm.log(1, cmd)
        base_comm.log(1, res)
    else:
        res_str = "\n".join(res)
        if "ERROR" in res_str:
            base_comm.log(1, res_str)
        else:
            base_comm.log(msg=res_str)


get_svc()
