#!/usr/bin/python
# -*- coding: UTF-8 -*-

import subprocess
import sys
import argparse

if sys.version.split('.')[0] == "2":
    reload(sys)
    sys.setdefaultencoding('utf8')


def args_parser():
    parser = argparse.ArgumentParser(description='Optional arguments for scheduler running.')
    parser.add_argument('-check', dest='check', type=str, help='disk_used')
    parser.add_argument('-match', dest='match', type=str, help='80')
    args = parser.parse_args()
    return args


def execute_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    if p.returncode == 0:
        return [cmd_res_compatible(i).strip("\n") for i in p.stdout.readlines()]
    else:
        print(p.stderr.readlines())
        sys.exit(1)


def cmd_res_compatible(line):
    if sys.version.split('.')[0] == "2":
        line.strip("\n")
    else:
        line.decode("utf-8").strip("\n")
    return line


def disk_mount(data):
    cmd_str1 = "cat /etc/fstab | grep -E '^/dev/' | grep -v 'swap' | awk '{print $1,$2}'"
    res = execute_cmd(cmd_str1)
    err_list = []
    for disk_info in res:
        disk = disk_info.split()
        cmd_str2 = "df -Th %s|awk 'NR>1{print $NF}'" % disk[0]
        df_res = execute_cmd(cmd_str2)
        if df_res[0] != disk[1]:
            err_list.append("%s mount error" % disk[0])
    if len(err_list) > 0:
        print("\n".join(err_list))
        sys.exit(1)


def cmd_res_judgment(cmd):
    res = execute_cmd(cmd)
    if res[0] != "0":
        sys.exit(1)


def disk_used(data):
    cmd_str = """df -Th |grep -Pv 'overlay|shm|/dev/loop|tmpfs'|awk 'NR >1{{gsub(/\%%/, ""); if ($6 > %s){{print $1,$$6,$NF}} }}' |wc -l""" % data.get("match")
    print(cmd_str)
    cmd_res_judgment(cmd_str)


def cpuidle(data):
    cmd_str = """cat /proc/stat|grep 'cpu '|awk '{print $1+$2+$3+$4+$5+$6+$7+$8+$9+$10,$5}' > /tmp/$USER/cpu_s;sleep 1;cat /proc/stat|grep 'cpu '|awk '{print $1+$2+$3+$4+$5+$6+$7+$8+$9+$10,$5}' > /tmp/$USER/cpu_e;pr -m -t /tmp/$USER/cpu_s /tmp/$USER/cpu_e|awk '{print ($4-$2)*100/($3-$1)}'|awk '{if(int($1)<30 && int($1)>0)print }'|wc -l"""
    cmd_res_judgment(cmd_str)


def swap_used(data):
    cmd_str = """free -g | grep -i 'swap' | awk '{if ($2==0) pass;else if ($3/$2>6) print $N}' | wc -l"""
    cmd_res_judgment(cmd_str)


def innode_used(data):
    cmd_str = """df -i|awk '{print $5}'|grep -E "^[0-9]"|sed 's/%//g'|awk '{if($1 > 80)print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def network_socket(data):
    cmd_str = """/usr/sbin/ss -s|sed -n '2p'|awk -F "estab " '{print $NF}'|awk -F"," '{if(int($1)>200000) print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def network_timewait(data):
    cmd_str = """/usr/sbin/ss -s|sed -n '2p'|awk -F "timewait " '{print $NF}'|awk -F"/" '{if(int($1)>20000) print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def ioawait(data):
    cmd_str = """cat /proc/diskstats|awk '{print $7+$11,$4+$8}' > /tmp/$USER/iowait_s;sleep 1; cat /proc/diskstats|awk '{print $7+$11,$4+$8}' > /tmp/$USER/iowait_e;pr -m -t /tmp/$USER/iowait_s /tmp/$USER/iowait_e|awk '{if($4-$2==0)print 0;else print ($3-$1)/($4-$2)}'|awk '{if ($1 > 1000) print }' | wc -l"""
    cmd_res_judgment(cmd_str)


def server_fd(data):
    cmd_str = """cat /proc/sys/fs/file-nr|while read U N T;do R=$[($U+$N)*100/$T];echo $R;done|awk '{if($1>80)print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def process_z(data):
    cmd_str = """ps -A -ostat,ppid,pid,cmd |grep -e '^[Zz]'|wc -l"""
    res = execute_cmd(cmd_str)
    if int(res[0]) > 20:
        sys.exit(1)


def network_card_in(data):
    cmd_str = """cat /proc/net/dev|awk '{print $2}'|grep -E '^[0-9]' > /tmp/$USER/recv_s;sleep 1;cat /proc/net/dev|awk '{print $2}'|grep -E '^[0-9]' > /tmp/$USER/recv_e;pr -m -t /tmp/$USER/recv_s /tmp/$USER/recv_e|awk '{print $1,$2}'|awk '{if($2-$1 >100)print $2-$1}'|awk '{if(int($1>5242880000))print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def network_card_out(data):
    cmd_str = """cat /proc/net/dev|awk '{print $10}'|grep -E '^[0-9]' > /tmp/$USER/send_s;sleep 1;cat /proc/net/dev|awk '{print $10}'|grep -E '^[0-9]' > /tmp/$USER/send_e;pr -m -t /tmp/$USER/send_s /tmp/$USER/send_e|awk '{print $1,$2}'|awk '{if($2-$1 >100)print $2-$1}'|awk '{if(int($1>5242880000))print $1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def network_drop_package(data):
    cmd_str = """cat /proc/net/dev|grep eth|awk '{print $5+$13}' > /tmp/$USER/eth_s;sleep 1;cat /proc/net/dev|grep eth|awk '{print $5+$13}' > /tmp/$USER/eth_e;pr -m -t /tmp/$USER/eth_s /tmp/$USER/eth_e|awk '{print $1,$2}'|awk '{if($2-$1 >100)print $2-$1}'|wc -l"""
    cmd_res_judgment(cmd_str)


def iouitl_used(data):
    cmd_str = """cat /proc/diskstats|awk '{print $13}' > /tmp/$USER/iouitl_s;sleep 1; cat /proc/diskstats|awk '{print $13}' > /tmp/$USER/iouitl_e;pr -m -t /tmp/$USER/iouitl_s /tmp/$USER/iouitl_e|awk '{print $1,$2}'|awk '{print $1,$2}'|awk '{if($2-$1 >600)print $2-$1}'|wc -l"""
    cmd_res_judgment(cmd_str)

def cpu_avg(data):
    if data.get("match") == "1":
        cmd_str="""w | awk - F'load average:' '/load average/ {print $2}' | awk - F',' '{print $1}'"""
    elif data.get("match") == "5":
        cmd_str = """w | awk - F'load average:' '/load average/ {print $2}' | awk - F',' '{print $2}'"""
    elif data.get("match") == "15":
        cmd_str = """w | awk - F'load average:' '/load average/ {print $2}' | awk - F',' '{print $3}'"""

def main():
    func_dict = {
        "disk_mount": disk_mount,
        "disk_used": disk_used,
        "cpuidle": cpuidle,
        "swap_used": swap_used,
        "innode_used": innode_used,
        "network_socket": network_socket,
        "network_timewait": network_timewait,
        "server_fd": server_fd,
        "process_z": process_z,
        "network_card_in": network_card_in,
        "network_card_out": network_card_out,
        "network_drop_package": network_drop_package,
        "iouitl_used": iouitl_used,
        "ioawait": ioawait,
        "cpu_avg": cpu_avg,
    }
    args = args_parser()
    if func_dict.get(args.check):
        func_dict.get(args.check)({"match": args.match})
    else:
        print("no support %s,support: %s" % (args.check, func_dict.keys()))


if __name__ == '__main__':
    main()
