#!/usr/bin/python
# -*- coding: UTF-8 -*-
import re
import subprocess
import sys
import logging

if sys.version.split('.')[0] == "2":
    from imp import reload

    reload(sys)
    sys.setdefaultencoding('utf8')

LOG_FORMAT = "%(asctime)s    [%(levelname)s]    %(message)s"
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)


def execute_cmd(cmd, return_str=False):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    if p.returncode == 0:
        result_list = [cmd_res_compatible(i) for i in p.stdout.readlines()]
    else:
        result_list = [cmd_res_compatible(i) for i in p.stderr.readlines()]

    if return_str:
        return p.returncode, "\n".join(result_list)
    else:
        return p.returncode, result_list


def cmd_res_compatible(line):
    if sys.version.split('.')[0] == "2":
        return line.strip("\n")
    else:
        return line.decode("utf-8").strip("\n")


def log(code=0, msg=""):
    if code == 0:
        logging.info(str(msg))
    elif code == 999:
        logging.warning(str(msg))
    else:
        logging.error(str(msg))


def pod_state(
        app_name,
        namespace="tce",
        expr="",
        cmd_list=None,
        pod_limit=None,
        age=None,
        is_ha=False,
        exec_args=None,
):
    cmd = (
            "kubectl get pod -n %s -o wide --no-headers| grep -E '%s' | awk -F ' +' '{print $1, $2, $3, $5, $6}'"
            % (namespace, app_name)
    )
    ret_code, ret_msg = execute_cmd(cmd)
    ret_msg = "\n".join(ret_msg)

    if ret_code != 0:
        logging.error(ret_msg)
        return 1, ret_msg
    elif len(ret_msg.strip()) == 0:
        msg = "未找到 {} pod容器".format(app_name)
        logging.error(msg)
        return 1, msg

    pod_list = [x.split() for x in ret_msg.split("\n") if len(x.strip()) > 0]
    # 限制循环几个pod
    if pod_limit is not None:
        try:
            _limit = int(pod_limit)
            pod_list = pod_list[:_limit]
        except ValueError:
            pass

    msg_dict = {
        x[0].strip(): "{} {}, age: {}".format(x[2].strip(), x[1].strip(), x[3].strip())
        for x in pod_list
    }

    fail_count = 0
    succ_count = 0
    not_running = 0
    has_ready = False

    age_reg_obj = re.compile(r"(\d+)(.+)")
    age_num = None
    age_unit = None
    if age is not None:
        result = age_reg_obj.findall(age)
        if len(result) != 0:
            age_num, age_unit = result[0]

    for p in pod_list:
        if len(p) == 5:
            pod_name, ready, run_state, pod_age, pod_ip = (
                p[0].strip(),
                p[1].strip(),
                p[2].strip(),
                p[3].strip(),
                p[4].strip(),
            )
        elif len(p) == 4:
            pod_name, ready, run_state, pod_ip = (
                p[0].strip(),
                p[1].strip(),
                p[2].strip(),
                p[3].strip(),
            )
            pod_age = None
        else:
            pod_name, ready, run_state = p[0].strip(), p[1].strip(), p[3].strip()
            pod_age = None
            pod_ip = "None"
        if run_state.strip().lower() in ["success", "completed"]:
            continue

        if run_state.strip().lower() in ["pending", "crashloopbackoff"]:
            if run_state.strip().lower() == "crashloopbackoff":
                json_path = '{"exitcode: "}{.status.containerStatuses[*].lastState.terminated.exitCode}{" ' \
                            'message: "}{.status.containerStatuses[*].state.waiting.message}'
                cmd_str = "kubectl -n %s get pod %s -o jsonpath='%s'" % (namespace, pod_name, json_path)
            else:
                cmd_str = "kubectl -n %s get pod %s -o jsonpath='{.status.conditions[*].message}'" % (
                    namespace, pod_name)
            ret_code, ret_msg = execute_cmd(cmd_str)
            logging.info(ret_msg)
            log_cmd = "kubectl -n %s logs --tail 100 %s" % (namespace, pod_name)
            ret_code, ret_msg = execute_cmd(log_cmd)
            logging.info(ret_msg)

        if run_state.strip().lower() != "running":
            fail_count += 1
            logging.error(p)
            continue

        # 判断容器存活时长
        if age_num and age_unit and pod_age:
            result = age_reg_obj.findall(pod_age)
            if len(result) != 0:
                _age_num, _age_unit = result[0]
                if age_unit == _age_unit:
                    if int(_age_num) < int(age_num):
                        fail_count += 1
                        continue
                else:
                    if age_unit == "d":
                        fail_count += 1
                        continue

        # 判断容器READY状态
        try:
            need, already = ready.split("/")
            need = int(need)
            already = int(already)
            if already != need:
                if is_ha is False:
                    logging.error(p)
                    fail_count += 1
                else:
                    not_running += 1
                continue
            else:
                has_ready = True
        except Exception:
            fail_count += 1
            logging.error(p)
            continue

        if cmd_list is None:
            succ_count += 1
            continue

        cmd_tmp = (
                "kubectl exec -i -n %s %s %s -- %s "
                % (namespace, pod_name, exec_args, cmd_list)
        )
        exec_status, exec_msg = execute_cmd(cmd_tmp, True)
        msg_dict[pod_name] += " | {}".format(exec_msg)
        if exec_status != 0:
            fail_count += 1
            logging.error("%s %s" % (cmd_tmp, exec_msg))
        else:
            if expr == "":
                succ_count += 1
                logging.info(exec_msg)
            else:
                expr_eval = re.sub("result", exec_msg, expr)
                if eval(expr_eval):
                    succ_count += 1
                    logging.info(expr_eval + " : True")
                else:
                    fail_count += 1
                    logging.info(expr_eval + " : False")
    if is_ha and not_running > 0 and has_ready is False:
        # 是高可用，且有没有满足running 1/1的容器，也没有满足的容器，则报失败
        fail_count += not_running
    else:
        succ_count += not_running

    last_msg = "\n".join(["{}: {}".format(k, v) for k, v in msg_dict.items()])
    if fail_count == 0:
        return 0, last_msg
    else:
        return 2, last_msg


def get_redis_auth(redis):
    code, auth_info = execute_cmd(
        "kubectl get redis %s -n sso -o jsonpath='{.spec.user}:{.spec.password}'|sed  's/\"//g'" % redis
    )
    if len(auth_info) == 0:
        return ""
    user = auth_info[0].split(':')

    if user[0] in ["null", ""]:
        if user[1] != "":
            auth = "-a '%s'" % user[1]
        else:
            auth = ""
    else:
        auth = "-a '%s'" % auth_info[0]

    return auth
