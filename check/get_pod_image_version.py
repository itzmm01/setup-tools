#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import csv
import os
import sys
import base_comm


def get_image_version():
    cmd = '''kubectl get deploy,ss,ds,sts -A -ojsonpath='{range .items[*]}{ .metadata.name}{","}{.spec.template.spec.containers[0].image}{"\\n"} {end}' '''
    code, res = base_comm.execute_cmd(cmd)
    if code != 0:
        base_comm.log(code, str(res))
        return 1
    else:
        csv_dir = os.getenv("TCS_TOOLS_DIR")
        if csv_dir is None:
            file_path = "image_version.csv"
        else:
            file_path = '%s/csv/image_version.csv' % csv_dir
        with open(file_path, "w") as f:
            writer = csv.writer(f)
            for row in res:
                row_list = row.split(",")
                writer.writerow(row_list)
        return 0


if get_image_version() != 0:
    sys.exit(1)
