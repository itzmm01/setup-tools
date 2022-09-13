#!/usr/bin/python
# -*- coding: UTF-8 -*-
import os
import logging
import argparse

parser = argparse.ArgumentParser(description='请输入对应的参数')
parser.add_argument('--threshold', help='判断磁盘占用最大的top10容器', type=int, default=10)
args = parser.parse_args()

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def analyze_disk_overlay2_top_n(threshold=10):
    cmd = "du -m /data/kubernetes/docker/overlay2/ --max-depth=1 2> /dev/null"
    cmd += "|awk '{if ($1 > %s) print $0}'" % (threshold * 1024)
    cmd += "|sort -nr|grep -wv /data/kubernetes/docker/overlay2/|head -n10"
    fs_list = list()
    for line in os.popen(cmd).readlines():
        if not line or len(line.split()) != 2:
            continue
        fs_list.append(line)

    if not fs_list:
        msg = "当前机器没有容器的磁盘占用大于%s G, 请查看看是否由于pod过多或者其他目录占用导致" % threshold
        logging.info(msg)
        return 0

    docker_dict = dict()
    cmd = "docker ps -q"
    for docker_id in os.popen(cmd).readlines():
        if not docker_id:
            continue

        docker_id = docker_id.lstrip().rstrip()
        cmd = "docker inspect %s|grep WorkDir|awk '{print $2}'" % docker_id
        work_dir = os.popen(cmd).read().lstrip().rstrip()
        docker_dict.update({docker_id: work_dir})

    for line in fs_list:
        for docker_id, work_dir in docker_dict.items():
            size = line.split()[0].lstrip().rstrip()
            fs = line.split()[1].lstrip().rstrip()
            if fs not in work_dir:
                continue

            cmd = "docker ps |grep %s|awk '{print $NF}'" % docker_id
            docker_name = os.popen(cmd).read().lstrip().rstrip()
            msg = "容器id %s, 容器名称 %s, 占用磁盘大小  %.2f G" % (docker_id, docker_name, float(size) / 1024)
            logging.info(msg)


if __name__ == '__main__':
    exit(analyze_disk_overlay2_top_n(args.threshold))
