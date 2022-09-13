#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import copy
import csv
import getpass
import hashlib
import binascii
import importlib
import io
import json
import logging
import logging.handlers
import multiprocessing
import os
import re
import socket
import subprocess
import sys
import time
import uuid
from contextlib import closing

import yaml

if sys.version.split('.')[0] == "2":
    reload(sys)
    sys.setdefaultencoding('utf8')

FILE_PATH = __file__
REAL_PATH = os.path.realpath(FILE_PATH)
CURRENT_PATH = os.path.dirname(REAL_PATH)
LOG_JOB_DIR = CURRENT_PATH
ENV_DICT = os.environ
result_status = []
user_name = getpass.getuser()
os.environ['PATH'] = os.getenv('PATH') + ":/tmp/tcl/bin"


class Constants(object):
    """
    the constants set of scheduler
    """
    TMP_SCRIPT_DIR = "/tmp/%s" % user_name
    SETUP_TOOLS_DIR = os.path.join(TMP_SCRIPT_DIR, "setup-tools")

    CONTROLLER_SEND_FILE_TOOLS = CURRENT_PATH + "/send_file.sh"
    CONTROLLER_SEND_CMD_TOOLS = CURRENT_PATH + "/send_cmd.sh"
    LOCAL_TIME_STAMP = time.time()
    STR_TIME_STAMP = time.strftime("%Y-%m-%d_%H-%M-%S", time.localtime(LOCAL_TIME_STAMP))
    LOG_SCHEDULER_FILE = CURRENT_PATH + '/scheduler.log.' + STR_TIME_STAMP
    LOG_JOB_FILE = CURRENT_PATH + '/job.log.' + STR_TIME_STAMP
    LOG_CSV_FILE = "%s/%s-%s" % (CURRENT_PATH, STR_TIME_STAMP, 'result.csv')
    LOG_SUMMARY_FILE = CURRENT_PATH + '/summary.log.' + STR_TIME_STAMP

    RECOVERY_FILE = "/tmp/recovery_log"
    LOCAL_HOST = "local"

    FILTER_STR = "*" * 6
    PASSWORD_PLACE_HOLDER = " -p '%s' " % FILTER_STR
    INTERNAL_GROUP_NAME = "ALL_NODES"

    KEYGEN_MODULE = "keygen"
    task_num = 0
    cur_task_num = 0
    TASK_NAME_SEND_COMMAND = "send_command"
    TASK_NAME_SEND_SOURCE_FILE = "send_source_file"
    TASK_NAME_EXECUTE_SCRIPT = "execute_script"
    TASK_NAME_CHECK_HOST_READY = "Check host ready"
    # CSV_LOGGER ignore
    CSV_LOG_IGNORE_TASKS = [TASK_NAME_SEND_COMMAND,
                            TASK_NAME_SEND_SOURCE_FILE,
                            TASK_NAME_EXECUTE_SCRIPT,
                            TASK_NAME_CHECK_HOST_READY]

    IP_SECTION_REGEX = re.compile(r'^(?:(?:[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.)'
                                  r'{3}(?:[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
                                  r'-(?:[1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')

    IP_REGEX = re.compile(r'^(?:(?:[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.)'
                          r'{3}(?:[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')

    GLOBAL_VAR_KEY = "global"
    GLOBAL_DEFAULT_USER = "root"
    GLOBAL_DEFAULT_PORT = 22


class LogUtils(object):
    # colorify status code for PRINT_LOGGER
    LOG_INFO_OK = "\033[0;32mok\033[0m"
    LOG_INFO_ERR = "\033[0;31merror\033[0m"
    LOG_INFO_WARN_SKIPPED = "\033[0;33mSkipped\033[0m"
    csv_file = Constants.LOG_CSV_FILE

    @staticmethod
    def get_log_file_name(param_data_key):
        if param_data_key in PARAM_DATA:
            if not CommonUtils.make_dirs(PARAM_DATA[param_data_key]):
                PRINT_LOGGER.info("Path for logfile [%s] not exists." % PARAM_DATA[param_data_key])
                sys.exit(1)
            else:
                return PARAM_DATA[param_data_key]
        return None

    @staticmethod
    def setup_file_logger(logger, log_file, log_level=logging.INFO, handler_level=logging.DEBUG,
                          fmt="%(processName)s - %(message)s"):
        logger.setLevel(log_level)
        file_handler = logging.handlers.RotatingFileHandler(filename=log_file, mode='w', maxBytes=1024 * 1024 * 50,
                                                            backupCount=5)
        file_handler.setLevel(handler_level)
        formatter = logging.Formatter(fmt)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    @staticmethod
    def setup_console_logger(logger, log_level=logging.INFO, handler_level=logging.DEBUG, fmt="%(message)s"):
        logger.setLevel(log_level)
        formatter = logging.Formatter(fmt)
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(handler_level)
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

    @staticmethod
    def execute_command_print_log(sub_process_return_code, host_location_name, print_out_lines, print_result,
                                  param_item=''):
        param_log = ""
        if param_item:
            param_log = " (\033[1;34m%s\033[0m)" % param_item
        # if print_result is True, print_out_lines already pint out lively
        # only when print_result is False and return_code isn't 0, print them out here
        if sub_process_return_code == 0:
            PRINT_LOGGER.info("    %s: %s%s" % (host_location_name, LogUtils.LOG_INFO_OK, param_log))
            if print_result:
                line = "\n".join(print_out_lines)
                PRINT_LOGGER.info(line)
        else:
            PRINT_LOGGER.info("    %s: %s%s" % (host_location_name, LogUtils.LOG_INFO_ERR, param_log))
            line = "\n".join(print_out_lines)
            PRINT_LOGGER.info(line)

    @staticmethod
    def execute_command_csv_log(sub_process_return_code, task_info, print_out_lines):
        host_location_name = task_info.get("host_location_name", "")
        task_name = task_info.get("task_name", "")
        print_result = task_info.get("print_result", False)
        line = ""
        if sub_process_return_code == 0:
            status = "OK"
            if print_result:
                line = "\n".join(print_out_lines)
        else:
            status = "ERROR"
            line = "\n".join(print_out_lines)
        with open(LogUtils.csv_file, "a+") as csvfile:
            if task_name not in ["unzip_setup-tools_file"]:
                w = csv.writer(csvfile)
                # 写入列头
                w.writerow([task_name, host_location_name, status, line, task_info.get("desc")])


class CsvLogPrinter(object):

    @staticmethod
    def print_format(max_long, content, flag=None):
        """
        Complementary output
        """
        num = 0
        if sys.version.split('.')[0] == "2":
            for char in content.decode("utf-8"):
                if u'\u4e00' <= char <= u'\u9fa5':
                    num += 1
            if flag:
                return content.ljust(max_long + num, flag)
            else:
                return content.ljust(max_long + num)
        else:
            for char in content:
                if '\u4e00' <= char <= '\u9fa5':
                    num += 1
            if flag:
                return content.ljust(max_long - num, flag)
            else:
                return content.ljust(max_long - num)

    @staticmethod
    def len_cn_zh(value):
        """
        Statistical length in Chinese and English
        """
        num = 0
        if sys.version.split('.')[0] == "2":
            for char in value.decode("utf-8"):
                if u'\u4e00' <= char <= u'\u9fa5':
                    num += 2
                else:
                    num += 1
        else:
            for char in value:
                if '\u4e00' <= char <= '\u9fa5':
                    num += 2
                else:
                    num += 1
        return num

    @staticmethod
    def get_csv_data(csv_path):
        csv_obj = csv.reader(open(csv_path, 'r'))
        csv_data = []
        group_csv_data = {}
        for line in csv_obj:
            if len(line) > 2 and line[2] == "OK":
                continue
            if group_csv_data.get(line[0]):
                host_list_str = group_csv_data[line[0]][1] + "\n" + line[1]
                group_csv_data[line[0]][1] = host_list_str
            else:
                group_csv_data[line[0]] = line

        for key in group_csv_data:
            row_line = []
            for row in group_csv_data[key]:
                row_list = row.split("\n")
                row_line.append(len(row_list))
            for num in range(max(row_line)):
                str1 = []
                for row in group_csv_data[key]:
                    row_list = row.split("\n")
                    if len(row_list) > num:
                        row_list_num = "" if '[INFO]' in row_list[num] else row_list[num]
                        str1.append(row_list_num)
                    else:
                        str1.append("")

                csv_data.append(str1)
        return csv_data

    @staticmethod
    def csv_to_table(csv_path):
        """
        Read CSV Convert to Table Output
        """
        title = ["TASK_NAME", "HOST", "STATUS", "LOGS", "DESC"]
        csv_data = CsvLogPrinter.get_csv_data(csv_path)
        table_data = []
        max_long_list = []
        for index, value in enumerate(title):
            max_long_list.append(max([CsvLogPrinter.len_cn_zh(data[index]) for data in csv_data]))
        division = "+"
        header = "|"
        for index, value in enumerate(max_long_list):
            division += CsvLogPrinter.print_format(value, "", "-") + "-"
            header += CsvLogPrinter.print_format(value, title[index]) + "|"

        table_data.append(division)
        table_data.append(header)
        table_data.append(division)
        log_color = {
            "OK": "\033[0;32mOK\033[0m",
            "ERROR": "\033[0;31mERROR\033[0m"
        }
        for data in csv_data:
            content_line = "|"
            early_return = False

            for index, value in enumerate(max_long_list):
                if data[index] == "TASK_NAME":
                    early_return = True
                    break
                else:
                    if data[index] == "ERROR":
                        content_line += log_color.get("ERROR") + " |"
                    elif data[index] == "OK":
                        content_line += log_color.get("OK") + "   " + " |"
                    else:
                        content_line += CsvLogPrinter.print_format(value, data[index], "") + "|"
            if early_return:
                continue
            else:
                table_data.append(content_line)
        table_data.append(division)

        for table_line in table_data:
            print(table_line)


class YamlUtils(object):
    @staticmethod
    def load_yaml_file(filename):
        if filename and os.path.exists(filename):
            try:
                with io.open(filename, 'r', encoding='utf-8') as file_name:
                    file_data = yaml.load(file_name, Loader=yaml.SafeLoader)
                return file_data or {}
            # pylint: disable=broad-except
            except Exception as _:
                PRINT_LOGGER.info("%s: yaml load %s error, please check %s format"
                                  % (LogUtils.LOG_INFO_ERR, filename, filename))
                sys.exit(1)
        else:
            PRINT_LOGGER.info("%s: %s file is not exists" % (LogUtils.LOG_INFO_ERR, filename))
            sys.exit(1)

    @staticmethod
    def dump_yaml_file(data, filename):
        with io.open(filename, 'w', encoding='utf-8') as file_name:
            yaml.safe_dump(data, file_name, default_flow_style=False)


class CommonUtils(object):

    @staticmethod
    def bytes2str(value):
        if sys.version.split('.')[0] == "2":
            return value
        if isinstance(value, bytes):
            return value.decode('utf-8')
        else:
            return value

    @staticmethod
    def get_cur_timestamp():
        return time.strftime("%Y-%m-%d %H:%M:%S")

    @staticmethod
    def str_to_int(num_str):
        try:
            return int(num_str)
        except ValueError:
            return None
        except TypeError:
            return None

    @staticmethod
    def str_to_float(num_str):
        try:
            return float(num_str)
        except ValueError:
            return None
        except TypeError:
            return None

    @staticmethod
    def get_local_ip():
        with closing(socket.socket(socket.AF_INET, socket.SOCK_DGRAM)) as _socket:
            try:
                _socket.connect(('8.8.8.8', 80))
                return _socket.getsockname()[0]
            # pylint: disable=broad-except
            except Exception as _:
                PRINT_LOGGER.info("get LOCAL_IP failed.")
                exit(1)

    @staticmethod
    def get_md5_value(data_str):
        my_md5 = hashlib.md5()
        my_md5.update(data_str.encode('utf-8'))
        return my_md5.hexdigest()

    @staticmethod
    def str2bool(value):
        if isinstance(value, bool):
            return value
        if str(value).lower() in ('yes', 'true', 't', 'y', '1'):
            return True
        elif str(value).lower() in ('no', 'false', 'f', 'n', '0'):
            return False
        else:
            raise argparse.ArgumentTypeError('Boolean value expected.')

    @staticmethod
    def make_dirs(file_path):
        abs_file_path = os.path.abspath(file_path)
        _path = os.path.dirname(abs_file_path)
        if not os.path.exists(_path):
            try:
                os.makedirs(_path)
            except OSError:
                return False
        return True

    @staticmethod
    def encrypt_data(dict_data, flag, dumps_file=None):
        if not dict_data.get("instance_key"):
            keygen = importlib.import_module(Constants.KEYGEN_MODULE)
            for k, v in dict_data.items():
                if k.endswith(flag):
                    dict_data["instance_key"] = keygen.generate_key().strip()
                    dict_data[k] = binascii.b2a_hex(keygen.encrypt(str(v), dict_data["instance_key"]))
            if dumps_file:
                YamlUtils.dump_yaml_file(dict_data, dumps_file)

    @staticmethod
    def decrypt_data(dict_data, flag):
        try:
            if dict_data.get("instance_key"):
                keygen = importlib.import_module(Constants.KEYGEN_MODULE)
                for k, v in dict_data.items():
                    if k.endswith(flag):
                        dict_data[k] = keygen.decrypt(
                            binascii.a2b_hex(dict_data[k].strip()), dict_data.get("instance_key")
                        )
            # return dict_data
        # pylint: disable=broad-except
        except Exception as err:
            PRINT_LOGGER.error("password decrypt error: %s" % err)
            raise err


class ParamReplaceHandler(object):

    @staticmethod
    def generate_param_item(key_list, param_item_info):
        param_item = []
        if key_list:
            for _key in key_list:
                if _key != "${SETUP_TOOLS_DIR}" and _key in param_item_info:
                    param_item.append(param_item_info[_key])
        return param_item

    @staticmethod
    def replace_single_quote(cmd, replace="'\\''", exclude="'\\\\''"):
        # find the index of all excluded strings
        index_dict = {sub.start(): sub.end() for sub in re.finditer(exclude, cmd)}
        if not index_dict:
            return cmd.replace("'", replace)
        replaced_str = ""
        idx = 0
        while idx < len(cmd):
            # skip the string which should be excluded.
            if idx in index_dict:
                replaced_str += cmd[idx:index_dict[idx]]
                idx = index_dict[idx]
                continue
            # replace the single quote with replace string
            if cmd[idx] == "'":
                replaced_str += replace
            else:
                replaced_str += cmd[idx]
            idx += 1
        return replaced_str

    @staticmethod
    def replace_param(value, params, replace_info=None):
        if replace_info is None:
            replace_info = {}
        for param in params:
            key = "${" + str(param) + "}"
            if key in str(value):
                value = str(value).replace(key, str(params[param]))
                replace_info.update({key: str(params[param])})
        return value

    @staticmethod
    def replace_param_param(replace_info=None):
        replace_info = {} if replace_info is None else replace_info
        for key, value in replace_info.items():
            for params in re.findall(r'\${\S*}', str(value)):
                param_name = re.sub(r'\$|{|}', '', params)
                replace_info.update({key: replace_info.get(param_name)})

    @staticmethod
    def replace_host_param(value, params, host_ip, replace_info=None):
        if replace_info is None:
            replace_info = {}
        for param in params:
            if "@" in param and param.split("@")[1] == host_ip:
                key = "${" + param.split("@")[0] + "}"
                value = str(value).replace(key, str(params[param]))
                replace_info.update({key: str(params[param])})
        return value

    @staticmethod
    def replace_operation(value, params):
        for param in params:
            tmp_param = params[param]
            if tmp_param and isinstance(tmp_param, list):
                float_list = list(filter(lambda x: x is not None, map(CommonUtils.str_to_float, tmp_param)))
                if float_list:
                    value = str(value).replace("${SUM(" + str(param) + ")}", str(sum(float_list))) \
                        .replace("${MIN(" + str(param) + ")}", str(min(float_list))) \
                        .replace("${MAX(" + str(param) + ")}", str(max(float_list))) \
                        .replace("${AVG(" + str(param) + ")}",
                                 str(round(sum(float_list) / len(float_list), 2)))
        return value

    @staticmethod
    def replace_key_words(value, host, replace_info=None):
        if replace_info is None:
            replace_info = {}
        host_ip = host.get("ip")
        value = value.replace("${IP}", host_ip)
        replace_info.update({"${IP}": host_ip})
        group = ",".join(host.get("group", ""))
        value = value.replace("${HOST_GROUP_NAME}", group)
        replace_info.update({"${HOST_GROUP_NAME}": group})
        pattern = "\${HOST_GROUP_IP_LIST\..*\w+}"
        group_list = re.findall(pattern, value)
        if group_list:
            _host_group = group_list[0].strip("${").strip("}")
            host_group = _host_group.split(".")[-1]
            if host_group in ALL_GROUP_HOST:
                host_group_ip_list = ",".join(ALL_GROUP_HOST.get(host_group))
                key = "${%s}" % _host_group
                value = value.replace(key, host_group_ip_list)
                replace_info.update({key: host_group_ip_list})
        return value


class HostParser(object):
    def __init__(self, host_yml_path):
        self.labels = {}
        self.group_refs = []
        self.group_ref_hosts = {}
        self.vars = {}
        self.hosts = {}
        self.host_conf_path = host_yml_path
        self.origin_yaml_data = YamlUtils.load_yaml_file(host_yml_path)
        self.all_hosts = []
        self.all_group_hosts = {}
        self.all_groups = []

    def parse(self):
        self.find_vars_and_labels()
        self.replace_labels()
        self.replace_vars()
        self.replace_group_refs()
        # merge the information of hosts found in group and group-ref
        self.merge_group_hosts()
        # parse ip section into ip list
        self.handle_ip_sections()
        self.list_all_hosts()
        self.all_groups = self.all_group_hosts.keys()

    def get_send_host_info(self, send_host):
        analyse_host = []
        if not send_host:
            return [], analyse_host
        if len(send_host) == 1 and Constants.LOCAL_HOST == send_host[0]:
            return [Constants.LOCAL_HOST], [Constants.LOCAL_HOST]
        send_host_list = []
        for _send_host in send_host:
            send_host_list.extend(list(map(lambda s: s.strip(), _send_host.split(","))))
        # find the ip list which we want to explain.
        explain_ip_list = set()
        for tmp_ip in send_host_list:
            if tmp_ip in self.all_groups:
                # if tmp_ip is a host group
                explain_ip_list.update(self.all_group_hosts[tmp_ip])
            else:
                # if tmp_ip is a ip or ip section, will call parse_host_ip function to parse it into ip list
                explain_ip_list.update(HostInfoHandler.parse_host_ip(tmp_ip))
        # find host info via ip
        for _ip in explain_ip_list:
            if Constants.LOCAL_HOST == _ip:
                analyse_host.append(_ip)
                continue
            for _temp_host in self.all_hosts:
                if _temp_host["ip"] == _ip:
                    analyse_host.append(_temp_host)
                    continue

        return explain_ip_list, analyse_host

    def list_all_hosts(self):
        temp_all_host_ips = {}
        for group_name, host_list in self.hosts.items():
            for _host in host_list:
                _ip = _host["ip"]
                # if host belongs one more group, will update the group info
                if _ip not in temp_all_host_ips:
                    self.all_hosts.append(_host)
                    temp_all_host_ips[_ip] = _host
                else:
                    temp_group_list = temp_all_host_ips[_ip].get("group", [])
                    if group_name not in temp_group_list:
                        temp_group_list.append(group_name)
                        temp_all_host_ips[_ip].update({"group": temp_group_list})

    def merge_group_hosts(self):
        for group_name, host_list in self.hosts.items():
            # keep the index of elements unchanged
            _temp_group_hosts = []
            host_list_new = copy.deepcopy(host_list)
            for _host in host_list_new:
                if len(_host.keys()) == 1 and _host.get("name", None):
                    HostParser.add_group_info(self.group_ref_hosts[_host["name"]], group_name)
                    _temp_group_hosts.extend(self.group_ref_hosts[_host["name"]])
                    continue
                HostParser.add_group_info([_host], group_name)
                _temp_group_hosts.append(_host)
                if _host.get("name") is not None:
                    for label in _host.get("name").split(","):
                        if self.hosts.get(label) is None:
                            self.hosts[label] = [_host]
                        else:
                            self.hosts.get(label).append(_host)

            self.hosts[group_name] = _temp_group_hosts

    @staticmethod
    def add_group_info(host_list, group_name):
        for host in host_list:
            host.setdefault("group", [Constants.INTERNAL_GROUP_NAME])
            if group_name not in host:
                host["group"].append(group_name)

    def handle_ip_sections(self):
        internal_group_hosts = set()
        for group_name, host_list in self.hosts.items():
            temp_host_list = []
            group_hosts = set()
            _temp_exists_host_ips = []
            for _host in host_list:
                host_ip = _host.get("ip", None)
                temp_ip_list = HostInfoHandler.parse_host_ip(host_ip)
                # append all ips to current host group
                group_hosts.update(set(temp_ip_list))
                internal_group_hosts.update(set(temp_ip_list))
                # single ip
                if len(temp_ip_list) == 1:
                    temp_host_list.append(copy.deepcopy(_host))
                    _temp_exists_host_ips.append(host_ip)
                    continue
                temp_host_list.extend(HostInfoHandler.generate_host_items(temp_ip_list, _host, _temp_exists_host_ips))
            self.all_group_hosts[group_name] = list(group_hosts)
            self.hosts[group_name] = temp_host_list
            self.all_group_hosts[Constants.INTERNAL_GROUP_NAME] = list(internal_group_hosts)

    def replace_group_refs(self):
        """
        replace group-refs with the actually group hosts
        :return:
        :rtype:
        """
        for group_ref in self.group_refs:
            # group ref, eg. NGI_GROUP[0:3]
            left_flag_idx = group_ref.rfind("[")
            _group = group_ref[:left_flag_idx]
            temp_group_hosts = self.hosts.get(_group, [])
            # cannot find the group for ref, will skip it and continue
            if not temp_group_hosts:
                self.group_ref_hosts.update({group_ref: temp_group_hosts})
                continue
            suffix = group_ref[left_flag_idx + 1:-1]
            if suffix == "*":
                self.group_ref_hosts.update({group_ref: temp_group_hosts})
            elif ":" in suffix:
                # have more than one ":", treat as wrong format
                if suffix.rfind(":") == suffix.find(":"):
                    index_arr = suffix.split(":")
                    # [:2] --> [0:2]
                    if not index_arr[0].strip():
                        _start_idx = 0
                    else:
                        _start_idx = CommonUtils.str_to_int(index_arr[0].strip())
                    # [1:] --> [1:len(ref)]
                    if not index_arr[1].strip():
                        _end_idx = len(temp_group_hosts)
                    else:
                        _end_idx = CommonUtils.str_to_int(index_arr[1].strip())
                    if _start_idx and _end_idx:
                        self.group_ref_hosts.update({group_ref: temp_group_hosts[_start_idx:_end_idx]})
            else:
                _idx = CommonUtils.str_to_int(suffix)
                if _idx is not None:
                    self.group_ref_hosts.update({group_ref: temp_group_hosts[_idx]})

    def replace_vars(self):
        global_vars = self.vars.get(Constants.GLOBAL_VAR_KEY, {})
        for group_name, update_host_list in self.hosts.items():
            group_vars = self.vars.get(group_name, {})
            for _update_host in update_host_list:
                _update_host_temp = copy.deepcopy(_update_host)
                if "ip" in _update_host:
                    # update host info, priority order from low to high: global_var-->group_var-->host_var
                    # eg. if host_var and group_var are both defined, will use host_var
                    _update_host.update(global_vars)
                    _update_host.update(group_vars)
                    _update_host.update(_update_host_temp)
                    # update by default value if not present
                    _update_host.setdefault("user", Constants.GLOBAL_DEFAULT_USER)
                    _update_host.setdefault("port", Constants.GLOBAL_DEFAULT_PORT)

    def replace_labels(self):
        for group_name, host_info_list in self.origin_yaml_data.items():
            if isinstance(host_info_list, list):
                self.hosts.setdefault(group_name, [])
                for _host in host_info_list:
                    _key_list = _host.keys()
                    # is a ref for label
                    if _key_list == ["name"] and _host["name"] not in self.group_refs:
                        self.hosts[group_name].extend(self.labels[_host["name"]])

    def find_vars_and_labels(self):
        """
        find the labels and vars defined in yaml file
        :return:
        :rtype:
        """
        for group_name, host_info_list in self.origin_yaml_data.items():
            if group_name.endswith("[var]"):
                self.vars.update({group_name.replace("[var]", ""): host_info_list})
                continue
            self.hosts.setdefault(group_name, [])
            for _host in host_info_list:
                _key_list = _host.keys()
                # the ref for label or group
                name_value = _host.get("name", "")
                if _key_list == ["name"]:
                    if name_value.rfind("[") > 0:
                        self.group_refs.append(name_value)
                    self.hosts[group_name].append(copy.deepcopy(_host))
                    continue
                # if find no "[", eg. MEETING_HOST it's a label
                self.hosts[group_name].append(copy.deepcopy(_host))
                if name_value and name_value.rfind("[") < 0:
                    self.labels.setdefault(name_value, [])
                    self.labels[name_value].append(copy.deepcopy(_host))
                    continue

    def encrypt(self):
        for host_group in self.origin_yaml_data:
            host_items = self.origin_yaml_data[host_group]
            if isinstance(host_items, dict):
                host_items = [host_items]
            for host_item in host_items:
                CommonUtils.encrypt_data(host_item, "password")
                # host has ip or name(label)
                host_item_name = host_item.get("ip", host_item.get("name", ""))
                LOGGER.info("encrypt password " + host_item_name + ": ok")
        YamlUtils.dump_yaml_file(self.origin_yaml_data, self.host_conf_path)

    def decrypt(self):
        try:
            for host_group in self.origin_yaml_data:
                host_items = self.origin_yaml_data[host_group]
                if isinstance(host_items, dict):
                    host_items = [host_items]
                for host_item in host_items:
                    CommonUtils.decrypt_data(host_item, "password")
        # pylint: disable=broad-except
        except Exception as err:
            LOGGER.exception(err)
            raise err


class HostInfoHandler(object):

    @staticmethod
    def get_group_ips(group_list, find_group_list):
        """
        get ips which include in groups
        :param group_list: group name list
        :param find_group_list: hosts defined in host.yml
        :return: eg. {"g1": ["192.9.X.X", 19.9.X.X"], "g2": ["192.9.X.X", 191.9.X.X"]}
        """
        group_host_dict = {}
        # specified groups or all groups
        if not group_list:
            group_list = find_group_list.keys()
        for group in group_list:
            if group != Constants.INTERNAL_GROUP_NAME and group in find_group_list:
                tmp_hosts = copy.deepcopy(find_group_list[group])
                for host in tmp_hosts:
                    host.pop("group", "")
                    host.pop("instance_key", "")
                    host.pop("password", "")
                group_host_dict[group] = tmp_hosts
        return group_host_dict

    @staticmethod
    def parse_host_ip(host_ip):
        ip_list = []
        if host_ip == Constants.LOCAL_HOST or Constants.IP_REGEX.match(host_ip):
            return [host_ip]
        # the ip section, eg. 10.1.X.X-XX
        if Constants.IP_SECTION_REGEX.match(host_ip):
            idx = host_ip.rfind(".")
            ip_prefix = host_ip[:idx + 1]

            ip_arr = host_ip[idx + 1:].split("-")
            ip_start = CommonUtils.str_to_int(ip_arr[0])
            ip_end = CommonUtils.str_to_int(ip_arr[1])
            if ip_start is None or ip_end is None:
                TASK_LOGGER.warning("parse ip section [%s] failed, please check the ip format." % host_ip)
                return ip_list
            ip_list = list(
                map(lambda ip_suffix: "%s%s" % (ip_prefix, ip_suffix), range(ip_start, min(ip_end + 1, 256))))
        return ip_list

    @staticmethod
    def generate_host_items(ip_list, host_item, exists_ips):
        generated_host_items = []
        for temp_ip in ip_list:
            if temp_ip not in exists_ips:
                tmp_host = copy.deepcopy(host_item)
                tmp_host["ip"] = temp_ip
                generated_host_items.append(tmp_host)
                exists_ips.append(temp_ip)
        return generated_host_items

    @staticmethod
    def get_host_ips(hosts):
        host_ips = []
        for host in hosts:
            if host == Constants.LOCAL_HOST:
                host_ips.append(host)
            else:
                host_ips.append(host["ip"])
        return host_ips


class Task(object):
    def __init__(self, task_dict):
        self.name = task_dict.get("name", "")
        self.type = task_dict.get("type", "")
        self.cmd = task_dict.get("cmd", "")
        self.desc = task_dict.get("desc", "")
        self.allow_failed = task_dict.get("allow_failed", False)
        try:
            self.time_out = task_dict.get("time_out", 0)
            if self.time_out == 0:
                self.time_out = SCHEDULER_ARGS.time_out
        except NameError:
            self.time_out = 120

        try:
            self.print_result = task_dict.get("print_result", None)
            if self.print_result is None:
                self.print_result = SCHEDULER_ARGS.print_result
        except NameError:
            self.print_result = False


def task_register(host, register, print_out_lines, vars_queue_lock, vars_queue):
    register_host = Constants.LOCAL_HOST if host == Constants.LOCAL_HOST else host["ip"]
    register_key = "%s@%s" % (register, register_host)
    print_out = print_out_lines[-1] if len(print_out_lines) > 0 else ""
    TASK_LOGGER.info("register param: " + register_key + " : " + str(print_out))
    register_dict = {
        register_key: print_out,
        register: print_out,
    }
    PARAM_DATA.update(register_dict)
    vars_queue_lock.acquire()
    vars_queue.update(register_dict)
    vars_queue_lock.release()


def task_print_log(cmd_item, task_info, sub_process, host_location_name, print_out_lines):
    param_item_info = cmd_item.get('param_item', [])
    key_list = cmd_item.get('key_list', [])
    print_result = task_info.get("print_result")
    param_item = ParamReplaceHandler.generate_param_item(key_list, param_item_info)
    if task_info.get("task_print_log"):
        print_result = True
    LogUtils.execute_command_print_log(sub_process.returncode, host_location_name, print_out_lines,
                                       print_result, param_item=",".join(param_item))
    if task_info.get("task_name") not in Constants.CSV_LOG_IGNORE_TASKS:
        LogUtils.execute_command_csv_log(sub_process.returncode, task_info, print_out_lines)


def call_proc(cmd_str, task_info, cmd_item, result_queue, vars_queue, vars_queue_lock):
    LOGGER.info("execute command, command is %s" % cmd_item.get('cmd', None))
    try:
        sub_process = subprocess.Popen(cmd_str, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT)
        # TASK_LOGGER.info("--------------------------------------------------")
        exit_code = 0
        host_location_name = task_info.get("host_location_name")
        host = task_info.get("host")
        register = task_info.get("register")
        exitcode_exp = task_info.get("exitcode_exp")
        print_log = task_info.get("print_log")
        print_result = task_info.get("print_result")
        _task_name = task_info.get("task_name")
        _is_check_ready = task_info.get("is_check_ready")
        print_out_lines = []
        if _task_name:
            TASK_LOGGER.info("task [%s] execute on host: %s" % (_task_name, str(host_location_name)))
        else:
            TASK_LOGGER.info("task execute on host: " + str(host_location_name))

        for line in iter(sub_process.stdout.readline, b''):
            line = CommonUtils.bytes2str(line)
            print_str = str.strip(line)
            if print_str and not "spawn ssh" in print_str and not print_str.startswith(
                    "Warning") and not print_str.startswith("Password:") \
                    and not print_str.startswith("Authorized") \
                    and not print_str.startswith("Permission denied") \
                    and not print_str.startswith("Connection to") \
                    and "password:" not in print_str:
                TASK_LOGGER.info(print_str)
                print_out_lines.append(print_str)

        sub_process.stdout.close()
        sub_process.wait()
        if register:
            task_register(host, register, print_out_lines, vars_queue_lock, vars_queue)
        if exitcode_exp:
            print_out = print_out_lines[-1] if len(print_out_lines) > 0 else ""
            host_ip = host.get("ip")
            exitcode_exp = exitcode_exp.replace("${IP}", host_ip)
            expr_eval = re.sub("result", print_out, exitcode_exp)
            expr_eval_new = ParamReplaceHandler.replace_param(expr_eval, PARAM_DATA)
            expr_eval_new = ParamReplaceHandler.replace_param(expr_eval_new, PARAM_DATA)
            if eval(expr_eval_new) is False:
                sub_process.returncode = 1
        if print_log:
            task_print_log(cmd_item, task_info, sub_process, host_location_name, print_out_lines)

        if not sub_process.returncode == 0:
            TASK_LOGGER.info("task [%s] execute on host: %s %s"
                             % (_task_name, str(host_location_name), LogUtils.LOG_INFO_ERR))
            # if check ready failed, mark it as unready and will be skipped when do any other tasks.
            if _is_check_ready:
                UNREADY_HOSTS.append(host_location_name)
            exit_code = 1
        else:
            TASK_LOGGER.info("task [%s] execute on host: %s %s"
                             % (_task_name, str(host_location_name), LogUtils.LOG_INFO_OK))

        result_status.append({
            "job": task_info.get("job_name"),
            "task": _task_name,
            "code": exit_code,
            "skip": True,
        })
        write_status()
        # TASK_LOGGER.info("--------------------------------------------------")
        TASK_LOGGER.info(" ")
        if exit_code != 0:
            result_queue.put(host_location_name)
        else:
            result_queue.put(exit_code)
    # pylint: disable=broad-except
    except Exception as err:
        print(err)
        LOGGER.exception(err)
        result_queue.put(1)


class Executor(object):

    @staticmethod
    def execute_parallel(task_info_list, parallel=False):
        pool = None
        if parallel:
            pool = multiprocessing.Pool(processes=PARAM_DATA["cpu_num"])
        manager = multiprocessing.Manager()
        result_queue = manager.Queue()
        vars_queue = multiprocessing.Manager().dict()
        vars_queue_lock = multiprocessing.Manager().Lock()
        exit_code, task_len = Executor.run_tasks(pool, result_queue, task_info_list, vars_queue, vars_queue_lock)
        if pool:
            pool.close()
            pool.join()
        PARAM_DATA.update(dict(vars_queue))
        exit_code = Executor.get_task_result(exit_code, result_queue, task_len)

        return exit_code

    @staticmethod
    def run_tasks(pool, result_queue, task_info_list, vars_queue, vars_queue_lock):
        exit_code = 0
        task_len = 0
        for task_info in task_info_list:
            cmd_list = task_info.get("cmd_list")
            host_location_name = task_info.get("host_location_name")
            item_condition = task_info.get("item_condition")
            with_items = task_info.get("with_items")
            host = task_info.get("host")
            _task_name = task_info.get("task_name")
            for cmd_item in cmd_list:
                if "item_condition" in cmd_item:
                    unmatch_item_condition = cmd_item["item_condition"]
                    # conditions not match, the exit_code will be 0
                    if unmatch_item_condition:
                        TASK_LOGGER.info(
                            "conditions not match, skipped on host: %s %s" % (str(host_location_name), item_condition)
                        )
                        status_info = {
                            "job": task_info.get("job_name"),
                            "task": _task_name,
                            "code": 0,
                            "skip": True,
                        }
                        PRINT_LOGGER.info("    %s: %s" % (str(host_location_name), LogUtils.LOG_INFO_WARN_SKIPPED,))
                    else:
                        status_info = {
                            "job": task_info.get("job_name"),
                            "task": _task_name,
                            "code": 1,
                            "skip": True,
                        }
                        TASK_LOGGER.info("params error, skipped on host: %s" % (str(host_location_name)))
                        PRINT_LOGGER.info("    %s: %s (\033[0;33mitems not found: %s\033[0m)"
                                          % (str(host_location_name), LogUtils.LOG_INFO_ERR, with_items))
                        exit_code = 1
                    result_status.append(status_info)
                    write_status()
                    continue
                cmd_str = cmd_item.get('cmd', None)
                if not cmd_str:
                    LOGGER.warning(
                        "couldn't find any cmd for task [%s] on host %s" % (_task_name, str(host_location_name)))
                    continue
                if host != Constants.LOCAL_HOST and "password" in host:
                    pwd_str = " -p '" + str(host["password"]) + "' "
                    cmd_str = cmd_str.replace(Constants.PASSWORD_PLACE_HOLDER, pwd_str)
                if pool:
                    pool.apply_async(call_proc,
                                     (cmd_str, task_info, cmd_item, result_queue, vars_queue, vars_queue_lock,))
                else:
                    call_proc(cmd_str, task_info, cmd_item, result_queue, vars_queue, vars_queue_lock)
                task_len += 1

        return exit_code, task_len

    @staticmethod
    def get_task_result(exit_code, result_queue, task_len):
        result_count = 0
        del UNREADY_HOSTS[:]
        while True:
            if result_count >= task_len:
                break
            result = result_queue.get()
            if result != 0:
                UNREADY_HOSTS.append(result)
                exit_code = 1
            result_count += 1

        return exit_code


class CmdTask(Task):
    def __init__(self, task_dict, is_check_ready=False):
        super(CmdTask, self).__init__(task_dict)
        self.register = task_dict.get("register", "")
        self.with_items = task_dict.get("with_items", "")
        self.item_condition = task_dict.get("item_condition", "")
        self.exitcode_exp = task_dict.get("exitcode_exp", "")
        self.parallel = task_dict.get("parallel", False)
        self.task_print_log = task_dict.get("print_log", False)
        self.is_check_ready = is_check_ready

    def parse_task_single(self, host, cmd, cmd_list, job_items, param_data, replace_info=None, key_list=None):
        replace_param_cmd = cmd
        if key_list is None:
            key_list = []
        if replace_info is None:
            replace_info = {}
        replace_info_item = {}
        replace_info_item.update(replace_info)
        if job_items:
            replace_param_cmd = ParamReplaceHandler.replace_param(cmd, job_items, replace_info_item)
        if self.item_condition:
            replace_item_condition = ParamReplaceHandler.replace_param(self.item_condition, param_data)
            _ip = Constants.LOCAL_HOST if host == Constants.LOCAL_HOST else host["ip"]
            replace_item_condition = replace_item_condition.replace("${IP}", _ip)
            replace_item_condition_new = ParamReplaceHandler.replace_param(replace_item_condition, param_data)
            TASK_LOGGER.info("replace condition is: " + str(replace_item_condition_new))
            if eval(replace_item_condition_new):
                cmd_list.append({"cmd": replace_param_cmd, "param_item": replace_info_item, "key_list": key_list})
            else:
                cmd_list.append({"item_condition": replace_item_condition_new})
        else:
            cmd_list.append({"cmd": replace_param_cmd, "param_item": replace_info_item, "key_list": key_list})

    def __generate_param_item(self, param):
        param_item = {}
        if isinstance(param, dict):
            for key, value in param.items():
                param_item[str(self.with_items + "." + key)] = value
        elif isinstance(param, str) or isinstance(param, (int, float)):
            param_item[str(self.with_items)] = str(param)
        else:
            TASK_LOGGER.info("unsupported param type %s, only support dict or str or number." % (type(param)))

        return param_item

    def parse_with_items(self, host, cmd, cmd_list, job_items, param_data, replace_info=None, key_list=None):
        _ip = Constants.LOCAL_HOST if host == Constants.LOCAL_HOST else host["ip"]
        _ip_with_items = self.with_items + "@" + _ip
        if self.with_items not in param_data and _ip_with_items not in param_data:
            TASK_LOGGER.info("can't find any task items(%s or %s)." % (self.with_items, _ip_with_items))
            cmd_list.append({"item_condition": None})
            return

        global_item_params = param_data.get(self.with_items)
        host_item_params = param_data.get(_ip_with_items)
        if host_item_params:
            item_params = host_item_params
        elif global_item_params:
            item_params = global_item_params
        else:
            TASK_LOGGER.info("task items %s and %s are empty, will do nothing." % (self.with_items, _ip_with_items))
            return

        if item_params:
            if key_list is None:
                key_list = []
            if replace_info is None:
                replace_info = {}
            for param in item_params:
                replace_info_item = {}
                replace_info_item.update(replace_info)
                param_item = self.__generate_param_item(param)
                # update task param_item by job_items
                # if job and task have the same key, will use the value defined in job
                if job_items:
                    param_item.update(job_items)
                # if elements of with_items are not dict type, param_item has the same key with param_data,
                # and we should use the key-value in param_item firstly
                replace_param_cmd = ParamReplaceHandler.replace_param(cmd, param_item, replace_info_item)
                replace_param_cmd = ParamReplaceHandler.replace_param(replace_param_cmd, param_data, replace_info_item)
                if self.item_condition:
                    replace_item_condition = ParamReplaceHandler.replace_param(self.item_condition, param_item)
                    replace_item_condition = replace_item_condition.replace("${IP}", _ip)
                    if eval(replace_item_condition):
                        cmd_list.append(
                            {"param_item": replace_info_item, "cmd": replace_param_cmd, "key_list": key_list})
                    else:
                        cmd_list.append({"item_condition": replace_item_condition})
                        params_key = self.with_items if global_item_params else self.with_items + "@" + _ip
                        TASK_LOGGER.info("command not execute because condition not match. ")
                        TASK_LOGGER.info("current item key: %s, item_condition: %s "
                                         % (params_key, self.item_condition))
                else:
                    cmd_list.append({"param_item": replace_info_item, "cmd": replace_param_cmd, "key_list": key_list})

    def run(self, hosts, param_data, job_name="", print_log=False, job_items=None, job_node_parallel=False):
        task_cmd = self.cmd
        if SCRIPT_PATH:
            task_cmd = "export PATH=$PATH:{0};{1}".format(SCRIPT_PATH, self.cmd)
        exit_code = 0
        sorted_replace_list = re.findall(r"\${\w+\.*\w+}", task_cmd)
        task_info_list = []
        for host in hosts:
            replace_info = {}
            cmd_list = []
            task_cmd = ParamReplaceHandler.replace_operation(task_cmd, param_data)
            if host == Constants.LOCAL_HOST:
                cmd = ParamReplaceHandler.replace_param(task_cmd, param_data, replace_info)
                cmd = ParamReplaceHandler.replace_param(cmd, PARAM_DATA)
                host_location_name = host
            else:
                # replace params with host ip
                replace_param_cmd = ParamReplaceHandler.replace_host_param(task_cmd, param_data,
                                                                           host["ip"], replace_info)
                replace_param_cmd = ParamReplaceHandler.replace_key_words(replace_param_cmd, host, replace_info)
                replace_param_cmd = ParamReplaceHandler.replace_param(replace_param_cmd, param_data, replace_info)
                replace_param_cmd = ParamReplaceHandler.replace_param(replace_param_cmd, PARAM_DATA)
                # single quote will make the cmd execute with wrong, replace them by '\''
                replace_param_cmd = ParamReplaceHandler.replace_single_quote(replace_param_cmd)
                cmd = Constants.CONTROLLER_SEND_CMD_TOOLS + " -i " + host["ip"] + " -P " + str(host["port"]) + " -u " \
                      + host["user"] + " -c '" + replace_param_cmd + "'"
                if "password" in host:
                    cmd = cmd + Constants.PASSWORD_PLACE_HOLDER
                cmd = cmd + " -t " + str(self.time_out)
                # if find nohup XXX, will execute cmd in background
                if re.findall(r"nohup\s+\w+", cmd):
                    cmd = cmd + " -b y"
                host_location_name = host["ip"]

            if self.with_items:
                self.parse_with_items(host, cmd, cmd_list, job_items, param_data, replace_info, sorted_replace_list)
            else:
                self.parse_task_single(host, cmd, cmd_list, job_items, param_data, replace_info, sorted_replace_list)
            task_info_list.append(
                {"host_location_name": host_location_name, "cmd_list": cmd_list, "task_name": self.name,
                 "print_log": print_log, "print_result": self.print_result, "register": self.register,
                 "item_condition": self.item_condition, "with_items": self.with_items, "host": host,
                 "is_check_ready": self.is_check_ready, "job_name": job_name, "desc": self.desc,
                 "exitcode_exp": self.exitcode_exp, "task_print_log": self.task_print_log
                 }
            )
            # every host do the task parallel
            if job_node_parallel and task_info_list:
                parallel_exit_code = Executor.execute_parallel(copy.deepcopy(task_info_list), job_node_parallel)
                if parallel_exit_code != 0:
                    exit_code = parallel_exit_code
                task_info_list = []
        if task_info_list:
            parallel_exit_code = Executor.execute_parallel(task_info_list, self.parallel)
            if parallel_exit_code != 0:
                exit_code = parallel_exit_code

        return exit_code


class ScriptTask(Task):
    def __init__(self, task_dict):
        super(ScriptTask, self).__init__(task_dict)
        self.local_script = task_dict.get("local_script", "")

    def run(self, hosts, task, param_data, job_name, job_node_parallel=False, job_param_item=None):
        # send local script to remote tmp dir
        _temp_task = {"src": self.local_script, "dest": Constants.TMP_SCRIPT_DIR, "time_out": self.time_out,
                      "name": self.name, "job_name": job_name}
        file_task = FileTask(_temp_task)
        file_task.run(hosts, False)
        # execute script cmd
        cmd_task = CmdTask(task)
        return_code = cmd_task.run(hosts, param_data, job_name, print_log=True, job_items=job_param_item,
                                   job_node_parallel=job_node_parallel)
        return return_code


class FileTask(Task):
    def __init__(self, task_dict):
        super(FileTask, self).__init__(task_dict)
        self.src = task_dict.get("src", "")
        self.dest = task_dict.get("dest", "")
        self.mode = task_dict.get("mode", "out")
        self.job_name = task_dict.get("job_name")
        self.run_script = task_dict.get("run_script")
        self.scp_out_mode = True if self.mode == "out" else False

    def run(self, hosts, print_log=False):
        exit_code = 0
        for host in hosts:
            if host == Constants.LOCAL_HOST:
                cmd = "cp " + self.src + " " + self.dest
                host_location_name = host
            else:
                src_replace = ParamReplaceHandler.replace_key_words(self.src, host)
                dest_replace = ParamReplaceHandler.replace_key_words(self.dest, host)
                cmd = Constants.CONTROLLER_SEND_FILE_TOOLS \
                      + " -i " + host["ip"] \
                      + " -P " + str(host["port"]) \
                      + " -u " + host["user"] \
                      + " -s " + src_replace \
                      + " -d " + dest_replace
                if "password" in host:
                    cmd = cmd + Constants.PASSWORD_PLACE_HOLDER
                cmd = cmd + " -t " + str(self.time_out)
                if not self.scp_out_mode:
                    cmd = cmd + " -m in"
                host_location_name = host["ip"]
            LOGGER.debug("execute cmd: " + cmd)
            try:
                if host != Constants.LOCAL_HOST and "password" in host:
                    pwd_str = " -p '" + str(host["password"]) + "' "
                    cmd = cmd.replace(Constants.PASSWORD_PLACE_HOLDER, pwd_str)
                sub_process = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                               stderr=subprocess.STDOUT)
                # TASK_LOGGER.info("--------------------------------------------------")
                if self.name:
                    TASK_LOGGER.info("file task [%s] execute on host: %s" % (self.name, str(host_location_name)))
                else:
                    TASK_LOGGER.info("file task execute on host: " + str(host_location_name))

                for line in iter(sub_process.stdout.readline, b''):
                    TASK_LOGGER.info(str.strip(CommonUtils.bytes2str(line)))
                sub_process.stdout.close()
                sub_process.wait()
                # TASK_LOGGER.info("--------------------------------------------------")
                TASK_LOGGER.info(" ")
                if sub_process.returncode == 0:
                    TASK_LOGGER.info("file task [%s] execute on host: %s %s"
                                     % (self.name, str(host_location_name), LogUtils.LOG_INFO_OK))
                    if print_log:
                        PRINT_LOGGER.info("    %s: %s" % (host_location_name, LogUtils.LOG_INFO_OK))
                else:
                    exit_code = 1
                    TASK_LOGGER.info("file task [%s] execute on host: %s %s"
                                     % (self.name, str(host_location_name), LogUtils.LOG_INFO_ERR))
                    if print_log:
                        PRINT_LOGGER.info("    %s: %s" % (host_location_name, LogUtils.LOG_INFO_ERR))
            # pylint: disable=broad-except
            except Exception as err:
                LOGGER.exception(err)
                exit_code = 1
                break
        status_info = {
            "job": self.job_name,
            "task": self.name,
            "code": exit_code,
            "skip": False,
        }
        result_status.append(status_info)
        write_status()
        return exit_code


include_file = []


class JobParser(object):
    def __init__(self, job_conf_path):
        self.origin_job_data = YamlUtils.load_yaml_file(job_conf_path)
        self.job_data = JobParser.get_job_list(self.origin_job_data)
        self.job_file_md5 = CommonUtils.get_md5_value(str(self.origin_job_data))
        self.job_abs_path = os.path.abspath(job_conf_path)
        self.jobs = [Job(_job["job"]) for _job in self.job_data]

    @staticmethod
    def uniq_task(include_jobs):
        _include_jobs_file = include_jobs["file"]
        if include_jobs.get("uniq"):
            if _include_jobs_file in include_file:
                return True, {}
        include_file.append(_include_jobs_file)
        include_jobs_file = JobParser.replace_include_jobs_param(_include_jobs_file)
        jobs_data = YamlUtils.load_yaml_file(include_jobs_file)
        return False, jobs_data

    @staticmethod
    def tmp_param(tmp_job, include_params):
        if include_params:
            if "include" in tmp_job:
                for i in tmp_job["include"]:
                    if i.get("params"):
                        i["params"].update(include_params)
                    else:
                        i["params"] = include_params
            else:
                if tmp_job["job"].get("param"):
                    tmp_job["job"]["param"].update(include_params)
                else:
                    tmp_job["job"]["param"] = include_params

    @staticmethod
    def get_job_list(jobs_data):
        jobs_list = []
        for _job in jobs_data:
            if "include" in _job:
                for include_jobs in _job["include"]:
                    skip, jobs_data = JobParser.uniq_task(include_jobs)
                    if skip:
                        continue
                    include_params = include_jobs.get("params")
                    if jobs_data and "with_items" in _job:
                        jobs_data["with_items"] = _job["with_items"]
                    for index, tmp_job in enumerate(jobs_data):
                        JobParser.tmp_param(tmp_job, include_params)
                        jobs_data[index] = tmp_job
                    jobs_list.extend(JobParser.get_job_list(jobs_data))
            else:
                jobs_list.append(_job)
        return jobs_list

    @staticmethod
    def replace_include_jobs_param(include_jobs_file):
        pattern = "\${\w+}"
        env_list = re.findall(pattern, include_jobs_file)
        for _key in env_list:
            key = _key.strip("${").strip("}")
            if ENV_DICT.get(key):
                value = ENV_DICT.get(key)
                include_jobs_file = include_jobs_file.replace(_key, str(value))
        return include_jobs_file


class Job(object):
    def __init__(self, job_dict):
        self.tasks = job_dict.get("tasks", [])
        self.name = job_dict.get("name", "")
        self.host = job_dict.get("host", Constants.LOCAL_HOST)
        self.condition = job_dict.get("condition", "")
        self.param = job_dict.get("param", {})
        self.with_items = job_dict.get("with_items", "")
        self.node_parallel = job_dict.get("node_parallel", False)

    def __str__(self):
        return "name:%s, host:%s, param:%s, condition:%s, with_items:%s, node_parallel:%s" \
               % (self.name, self.host, self.param, self.condition, self.with_items, self.node_parallel)


class RecoveryInfoHandler(object):

    @staticmethod
    def do_remove_recovery_info():
        if os.path.exists(Constants.RECOVERY_FILE):
            try:
                os.remove(Constants.RECOVERY_FILE)
            except IOError:
                PRINT_LOGGER.info("Clear recovery info failed.")
                sys.exit(1)
        PRINT_LOGGER.info("Clear recovery info ok.")
        sys.exit(0)

    @staticmethod
    def do_get_recovery_info(recovery_job_file):
        recovery_info = []
        if os.path.exists(Constants.RECOVERY_FILE):
            recovery_info = RecoveryInfoHandler.get_recovery_info(job_file_name=recovery_job_file)
        print(json.dumps(recovery_info, indent=4, ensure_ascii=False))
        sys.exit(0)

    @staticmethod
    def clear_recovery_data(data, now_timestamp=time.time()):
        new_data = {}
        for recovery_id in data:
            recovery_id_info = data.get(recovery_id)
            recovery_timestamp = recovery_id_info.get("timestamp")
            recovery_timestamp = time.mktime(time.strptime(recovery_timestamp, "%Y-%m-%d_%H-%M-%S"))
            time_difference = now_timestamp - recovery_timestamp
            if time_difference < 604800:
                new_data[recovery_id] = recovery_id_info
        return new_data

    @staticmethod
    def get_recovery_info(job_file_name=None):
        new_data = []
        job_data = []
        data = YamlUtils.load_yaml_file(Constants.RECOVERY_FILE)
        if data:
            if job_file_name:
                job_file_name = os.path.abspath(job_file_name)
            for recovery_id in data:
                recovery_id_info = data.get(recovery_id)
                _job_file_name = recovery_id_info.get("job_file_name")
                _recovery_timestamp = recovery_id_info.get("timestamp")
                _recovery_info = {"recovery_id": recovery_id, "job_file_name": _job_file_name,
                                  "timestamp": _recovery_timestamp}
                if job_file_name == _job_file_name:
                    timestamp = time.mktime(time.strptime(_recovery_timestamp, "%Y-%m-%d_%H-%M-%S"))
                    if job_data:
                        if timestamp > time.mktime(time.strptime(job_data[0].get("timestamp"), "%Y-%m-%d_%H-%M-%S")):
                            job_data = [_recovery_info]
                    else:
                        job_data.append(_recovery_info)
                new_data.append(_recovery_info)
            if job_file_name:
                return job_data
        return new_data


class ParseArgs(argparse.Action):
    inner_dict = {}

    def __call__(self, parser, namespace, values, option_string=None):
        args_key, args_value = values.split("=", 1)
        ParseArgs.inner_dict.update({args_key: args_value})
        setattr(namespace, self.dest, ParseArgs.inner_dict)


def parse_args():
    parser = argparse.ArgumentParser(description='Optional arguments for scheduler running.')
    parser.add_argument('-c', dest='job_conf', type=str, help='<job file>  job yaml config file')
    parser.add_argument('-i', dest='host_conf', type=str, help='<host file>  host yaml config file')
    parser.add_argument('-p', dest='param_conf', type=str, help='<param file> optional, param yaml config file')
    parser.add_argument('-s', dest='send_file', type=CommonUtils.str2bool, default=False,
                        help='y/n  optional, whether send setup-tools file or not. default is n')
    parser.add_argument('-sc', dest='command', type=str, help='<command>  send command to you want host')
    parser.add_argument('-sf', dest='source_file_path', type=str,
                        help='<source file path> send file to host source path')
    parser.add_argument('-sp', dest='script_path', type=str,
                        help='script path, Please use "," to separate multiple directories.example: -sp "path1,path2')
    parser.add_argument('-sl', dest='script_local_path', type=str, help='local script path,will be sent to remote.')
    parser.add_argument('-dp', dest='dest_path', type=str, help='<destination path>  send file destination path')
    # multiple -sh parameters will append to a list
    parser.add_argument('-sh', dest='send_host', action='append', type=str,
                        help='<ip or host group> send command or file to host')
    parser.add_argument('-sm', dest='scp_out_mode', type=str, help='<scp mode> scp file in or out. default is out')
    parser.add_argument('-pr', dest='print_result', type=CommonUtils.str2bool, default=False,
                        help='y/n whether print result')
    parser.add_argument('-ep', dest='encrypt', type=CommonUtils.str2bool, default=False,
                        help='y/n whether encrypt host.yml password')
    # with nargs="*", this arg will be parsed as a list, eg. -qi host1,host2 --> ['host1,host2']
    # if without value, such as -qi, will return [], if cannot find -qi, will return None
    parser.add_argument('-qi', dest='query_ips', nargs="*", type=str,
                        help='<param file> optional, param yaml config file')
    parser.add_argument('-j', dest='start_job_name', type=str,
                        help='<job name> start the deploy from the specified job name, to skip some steps')
    parser.add_argument('-mp', dest='modify_port', type=int,
                        help='<port> modify the sshd port for hosts defined in -sh param,'
                             ' if without -sh, all hosts in yml as default')
    parser.add_argument('-t', dest='time_out', type=int, default=120,
                        help='<timeout> The timeout of a single task execution, in seconds')
    parser.add_argument('-ch', dest='ignore_check_ready_failed', type=CommonUtils.str2bool, default=False,
                        help='y/n whether ignore the failed of check host ready or not. default is n')
    parser.add_argument('-rc', dest='recovery', type=CommonUtils.str2bool, default=False,
                        help='y/n, whether open the recovery mode, default is n')
    parser.add_argument('-gi', dest='get_recovery_data', type=CommonUtils.str2bool, default=False,
                        help='y/n, whether get recovery info, default is n')
    parser.add_argument('-gc', dest='remove_recovery_data', type=CommonUtils.str2bool, default=False,
                        help='y/n, whether remove recovery info, default is n')
    parser.add_argument('-fr', dest='force_reset_recovery', type=CommonUtils.str2bool, default=False,
                        help='y/n, whether reset recovery info in force, default is n')
    parser.add_argument('-ri', dest='recovery_id', type=str, help='start your job from this recovery id.')
    parser.add_argument('-gf', dest='recovery_job_file', type=str, help='job file name for get recovery info operation')
    parser.add_argument('-g', dest='global_param', action=ParseArgs,
                        help='k=v optional, global params. eg. LOG_JOB_PATH="/data/test.log"')
    parser.add_argument('-table', dest='display_table', type=CommonUtils.str2bool, default=False,
                        help='y/n, Whether to display an error summary, default is n')
    parser.add_argument('-pool', dest='pool_num', type=int, default=0,
                        help='The number of multiple processes. The default is the number of CPU cores')
    parser.add_argument('-host', dest='host', type=str, default="",
                        help='hostinfo ip,user,password,port')

    args = parser.parse_args()
    special_args_handle(args)
    return args


def special_args_handle(args):
    if args.query_ips is None:
        args.do_query_ips = False
    else:
        args.do_query_ips = True
        if args.query_ips:
            args.query_ips = ",".join(args.query_ips).split(",")
    args.scp_out_mode = True
    if args.scp_out_mode is None or args.scp_out_mode == "in":
        args.scp_out_mode = False
    if args.send_host:
        args.send_host = list(set(args.send_host))
    if args.global_param:
        GLOBAL_PARAM.update(args.global_param)


def check_modify_host(yml_hosts, modify_host):
    valid = True
    if not modify_host.strip():
        return valid
    yml_host_defined = []
    for group_name in yml_hosts.keys():
        for tmp_group_host in yml_hosts[group_name]:
            if "ip" in tmp_group_host and "port" in tmp_group_host:
                yml_host_defined.append(tmp_group_host["ip"])
    for tmp_host in modify_host.split(","):
        if tmp_host.strip() not in yml_host_defined:
            TASK_LOGGER.warning("modify host [%s] not in yml_hosts." % tmp_host)
            PRINT_LOGGER.warning("modify host [%s] not in yml_hosts." % tmp_host)
            valid = False
            break
    return valid


def check_host_ready(hosts, time_out=5, print_log=True):
    PRINT_LOGGER.info("  task: Check host ready")
    execute_command(
        hosts, "date >/dev/null", time_out, print_log,
        False, task_name="check_host_ready",
        is_check_ready=True, parallel=True
    )
    ready_host = []
    for index, value in enumerate(hosts):
        if value == "local":
            ready_host.append(value)
            continue
        if value.get("ip") not in UNREADY_HOSTS:
            ready_host.append(value)
    return ready_host


def exec_modify_sshd_port(port, target_hosts, time_out=120, print_result=True):
    # 1.modify Port/UseDNS/GSSAPIAuthentication properties in /etc/ssh/sshd_config
    set_port_status_code = exec_set_ssh_config(target_hosts, "Port", port, time_out=time_out, print_result=print_result)
    ret_code = 1
    if set_port_status_code == 0:
        exec_set_ssh_config(target_hosts, "UseDNS", "no", time_out=time_out, print_result=print_result)
        exec_set_ssh_config(target_hosts, "GSSAPIAuthentication", "no", time_out=time_out, print_result=print_result)
        # 2.restart sshd service
        restart_sshd_service_cmd = "systemctl restart sshd"
        PRINT_LOGGER.info("  task: Restart sshd service")
        restart_sshd_status_code = execute_command(target_hosts, restart_sshd_service_cmd, time_out, True,
                                                   print_result, task_name="Restart sshd service")
        if restart_sshd_status_code == 0:
            # 3.check the result of modify
            for tmp_host in target_hosts:
                if "port" in tmp_host:
                    tmp_host["port"] = port
            PRINT_LOGGER.info("  task: Check ssh connection available")
            check_sshd_conn_code = execute_command(target_hosts, "ls >/dev/null", time_out, True,
                                                   True, task_name="Check ssh connection available")
            ret_code = check_sshd_conn_code
            if ret_code != 0:
                PRINT_LOGGER.info("    check ssh connection available error.")
        else:
            PRINT_LOGGER.info("    restart sshd service error.")
    else:
        PRINT_LOGGER.info("    set ssh port error.")

    return ret_code


def modify_host_port(modify_host, port, yml_hosts):
    for group_name in yml_hosts:
        for tmp_host in yml_hosts[group_name]:
            if "port" not in tmp_host:
                continue
            if modify_host:
                # group_name found in modify_host and the ips found in modify_host
                if (group_name in modify_host) or ("ip" in tmp_host and tmp_host["ip"] in modify_host):
                    tmp_host["port"] = port
            else:
                # modify_host is empty, will modify the port for all hosts
                tmp_host["port"] = port


def exec_set_ssh_config(hosts, config_key, config_value, time_out=120, print_result=True):
    _task_name = "SET ssh config : %s=%s" % (config_key, config_value)
    PRINT_LOGGER.info("  task: " + _task_name)
    allowed_modify_config_keys = ["UseDNS", "GSSAPIAuthentication", "Port"]
    if config_key not in allowed_modify_config_keys:
        PRINT_LOGGER.info("    Cannot SET ssh config : %s" % config_key)
        return 1
    sshd_config_path = "/etc/ssh/sshd_config"
    # 1. replace config contents with space 2. append config info to the config file.
    set_sshd_config_cmd = "sed -i 's/^%s .*/ /g' %s; echo -e '\n%s %s\n' >> %s" \
                          % (config_key, sshd_config_path, config_key, config_value, sshd_config_path)
    TASK_LOGGER.info("SET ssh config : %s=%s" % (config_key, config_value))
    return execute_command(hosts, set_sshd_config_cmd, time_out, True, print_result, task_name=_task_name)


def cmd_res_compatible(line):
    if sys.version.split('.')[0] == "2":
        return line.strip("\n")
    else:
        return line.decode("utf-8").strip("\n")


def send_setup_tools_file(hosts, time_out=120):
    get_version_cmd = "cat %s/../version" % CURRENT_PATH
    p = subprocess.Popen(get_version_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    ready_host = check_host_ready(hosts, print_log=False)
    send_hosts = []
    if p.returncode == 0:
        current_version = "\n".join([cmd_res_compatible(i) for i in p.stdout.readlines()])
        get_version_cmd = "cat %s/version" % Constants.SETUP_TOOLS_DIR

        _cmd_task_dict = {
            "cmd": get_version_cmd, "time_out": time_out, "name": "判断远端版本号",
            "is_check_ready": True, "parallel": True, "exitcode_exp": "'result' == '%s'" % current_version,
        }
        _cmd_task = CmdTask(_cmd_task_dict)
        _cmd_task.run(ready_host, PARAM_DATA, print_log=False)
        for i, v in enumerate(ready_host):
            if v.get("ip") in UNREADY_HOSTS:
                send_hosts.append(v)
    else:
        send_hosts = [i for i in ready_host]

    setup_tools_zip_file_name = "setup-tools.tar.gz"
    tmp_zip_file = os.path.dirname(os.path.dirname(CURRENT_PATH)) + "/" + setup_tools_zip_file_name
    # remove temp file
    if os.path.exists(setup_tools_zip_file_name):
        os.remove(setup_tools_zip_file_name)
    # tar temp file
    cmd = "cd %s;tar -czPf %s ./*" % (os.path.dirname(CURRENT_PATH), tmp_zip_file)
    LOGGER.info("zip setup tool: " + cmd)
    os.system(cmd)

    LOGGER.info("clean ")
    cmd = "rm -rf %s ; mkdir -p %s " % (Constants.TMP_SCRIPT_DIR, Constants.SETUP_TOOLS_DIR)
    execute_command(send_hosts, cmd, time_out=time_out, print_log=False, print_result=False,
                    task_name="clean", parallel=True
                    )

    LOGGER.info("send setup-tools zip file...")
    code = execute_file(send_hosts, tmp_zip_file, Constants.TMP_SCRIPT_DIR + "/" + setup_tools_zip_file_name,
                        job_name="job_name",
                        time_out=time_out, task_name="send_setup-tools_file")
    if code != 0:
        TASK_LOGGER.error("copy setup-tools failed")
        sys.exit(code)
    LOGGER.info("unzip_setup-tools_file")
    cmd = "tar xf %s/%s -C %s" % (
        Constants.TMP_SCRIPT_DIR, setup_tools_zip_file_name,
        Constants.SETUP_TOOLS_DIR)
    execute_command(send_hosts, cmd, time_out=time_out, print_log=True, print_result=True,
                    task_name="unzip_setup-tools_file", parallel=True
                    )
    # remove local tmp zip package
    os.remove(tmp_zip_file)
    return 0


def execute_command(hosts, cmd, time_out, print_log=False, print_result=False, task_name="", is_check_ready=False,
                    parallel=False
                    ):
    _cmd_task_dict = {"cmd": cmd, "time_out": time_out, "name": task_name,
                      "is_check_ready": is_check_ready, "print_result": print_result}
    if parallel:
        _cmd_task_dict["parallel"] = True
    _cmd_task = CmdTask(_cmd_task_dict)
    return _cmd_task.run(hosts, PARAM_DATA, print_log=print_log)


def execute_file(hosts, src, dest, time_out, job_name="", out_mode="out", print_log=False, task_name=""):
    _file_task_dict = {"src": src, "time_out": time_out, "name": task_name, "dest": dest,
                       "out_mode": out_mode, "job_name": job_name}
    _file_task = FileTask(_file_task_dict)
    return _file_task.run(hosts, print_log)


def add_task_num(job_parser):
    for job in job_parser.job_data:
        if job.get("job") and job["job"].get("tasks"):
            Constants.task_num += len(job["job"]["tasks"])


def job_condition(job):
    if job.condition:
        replace_job_condition = ParamReplaceHandler.replace_param(job.condition, PARAM_DATA)
        replace_job_condition = ParamReplaceHandler.replace_param(replace_job_condition, job.param)
        TASK_LOGGER.info("replace job condition is: " + str(replace_job_condition))
        # found condition, but condition doesn't match
        if not eval(replace_job_condition):
            PRINT_LOGGER.info("job [%s] will be skipped. condition doesn't match." % str(job.name))
            Constants.cur_task_num += len(job.tasks)
            return True
    return False


def execute_jobs(send_host_ip_list):
    scheduler_return_code = 0
    job_parser = JobParser(SCHEDULER_ARGS.job_conf)
    add_task_num(job_parser)
    recovery_data, recovery_id = do_init_recovery_info(job_parser.job_abs_path, job_parser.job_file_md5)
    start_exec_job = False
    for job in job_parser.jobs:
        job_name = str(job.name)
        # start from the specified job name
        if SCHEDULER_ARGS.start_job_name and job_name == SCHEDULER_ARGS.start_job_name:
            start_exec_job = True
        if SCHEDULER_ARGS.start_job_name and not start_exec_job:
            PRINT_LOGGER.info("job [%s] will be skipped as your setting" % job_name)
            LOGGER.info("job [%s] will be skipped as your setting" % job_name)
            continue

        analyse_hosts, job_host = get_analyse_hosts(job.host, send_host_ip_list, job.param)
        PARAM_DATA.update({"ANALYSE_JOB_HOSTS": analyse_hosts})
        # condition of job
        if job_condition(job):
            continue
        if not analyse_hosts:
            Constants.cur_task_num += len(job.tasks)
            PRINT_LOGGER.info("%s: job break because no host execute.  job host: %s"
                              % (LogUtils.LOG_INFO_ERR, job_host if job_host else job.host))
            LOGGER.info("job break because no host execute.  job host: %s"
                        % job_host if job_host else job.host)
            job_return_code = 1
        else:
            job_name = str(ParamReplaceHandler.replace_param(job_name, PARAM_DATA))
            LOGGER.info("execute job: " + job_name)
            PRINT_LOGGER.info("job: " + job_name)
            LOGGER.info("job will execute on host: " + str(HostInfoHandler.get_host_ips(analyse_hosts)))
            job_md5 = CommonUtils.get_md5_value(str(job))
            # skip the jobs already marked as success
            if do_recovery(job_md5, job_name, job_parser, recovery_data, recovery_id):
                Constants.cur_task_num += len(job.tasks)
                continue
            allow_failed_num, job_return_code, summary_log = execute_job(analyse_hosts, job, job_name)
            save_recovery_info(job_md5, job_return_code, recovery_data, recovery_id)
            if job_return_code != 0:
                scheduler_return_code = job_return_code
                TASK_LOGGER.info("****%s end job: [%s] execute %s" % (CommonUtils.get_cur_timestamp(),
                                                                      job_name, LogUtils.LOG_INFO_ERR))
                if summary_log:
                    TASK_LOGGER.info("****Summary for job [%s] : %s, AllowFailed: %s"
                                     % (job_name, summary_log, allow_failed_num))
            else:
                TASK_LOGGER.info("****%s job: [%s] execute %s" % (CommonUtils.get_cur_timestamp(),
                                                                  job_name, LogUtils.LOG_INFO_OK))
                if summary_log:
                    TASK_LOGGER.info("****Summary for job [%s] : %s" % (job_name, summary_log))

        if ("allow_failed" not in job.param or not job.param["allow_failed"]) and job_return_code != 0:
            LOGGER.info("job break because job " + job_name + " must all task success.")
            break
    if SCHEDULER_ARGS.recovery:
        YamlUtils.dump_yaml_file(recovery_data, Constants.RECOVERY_FILE)

    return scheduler_return_code


def execute_job(analyse_hosts, job, job_name):
    job_item_params = PARAM_DATA.get(job.with_items, [None])
    total_task_num = len(job.tasks) * len(job_item_params)
    job_return_code = 0
    exec_task_num = 0
    succ_task_num = 0
    failed_task_num = 0
    allow_failed_num = 0
    analyse_hosts = check_host_ready(analyse_hosts)
    for job_items in job_item_params:
        job_param_item = generate_job_items(job_items, job.with_items)
        TASK_LOGGER.info("****%s start job: %s" % (CommonUtils.get_cur_timestamp(), job_name))
        for task in job.tasks:
            if task["name"] not in [
                "Check host ready", "unzip_setup-tools_file", "判断远端版本号", "check_host_ready"
            ]:
                Constants.cur_task_num = Constants.cur_task_num + 1
            if not task.get("execute"):
                exec_task_num += 1
                if job.param:
                    print(" (\033[1;34m%s\033[0m)" % job.param)
                for k, v in task.items():
                    tmp_value = str(ParamReplaceHandler.replace_param(task.get(k, ""), PARAM_DATA))
                    value = str(ParamReplaceHandler.replace_param(tmp_value, job.param))
                    task[k] = value
                task_name = task["name"]
                init_task_own_log_file(job.param, task_name)
                PRINT_LOGGER.info("  task: " + task_name)
                TASK_LOGGER.info("  task: " + task_name)
                LOGGER.info("execute task [%s] in job [%s]" % (task_name, job_name))
                return_code = execute_task(analyse_hosts, task, PARAM_DATA, job_name, job.node_parallel, job_param_item)
                if return_code != 0:
                    if "allow_failed" in task and task["allow_failed"]:
                        allow_failed_num += 1
                    else:
                        job_return_code = return_code
                    failed_task_num += 1
                else:
                    succ_task_num += 1
                if ("allow_failed" not in task or not task["allow_failed"]) and return_code != 0:
                    LOGGER.info("job break because task " + task_name + " must success.")
                    break
    summary_log = "Total: %s, Executed: %s, Success: %s, Failed: %s" \
                  % (total_task_num, exec_task_num, succ_task_num, failed_task_num)
    return allow_failed_num, job_return_code, summary_log


def execute_task(analyse_hosts, task, param_data, job_name, job_node_parallel=False, job_param_item=None):
    if "task_own_log_file" in task:
        task_own_log_file = os.path.join(Constants.TMP_SCRIPT_DIR, "task-%s.log" % (task["task_own_log_file"]))
        LogUtils.setup_file_logger(TASK_LOGGER, task_own_log_file)

        task_own_scheduler_log_file = os.path.join(Constants.TMP_SCRIPT_DIR,
                                                   "task-%s-schedule.log" % (task["task_own_log_file"]))
        LogUtils.setup_file_logger(LOGGER, task_own_scheduler_log_file,
                                   fmt="%(asctime)s - %(levelname)s: %(message)s")
    start_time = time.time()
    if task["type"] == "command":
        cmd_task = CmdTask(task)
        return_code = cmd_task.run(analyse_hosts, param_data, job_name, print_log=True, job_items=job_param_item,
                                   job_node_parallel=job_node_parallel)
    elif task["type"] == "file":
        src = ParamReplaceHandler.replace_param(task["src"], param_data)
        dest = ParamReplaceHandler.replace_param(task["dest"], param_data)
        LOGGER.info("execute file transfer, src is " + src + " , dest is " + dest)
        task["src"] = src
        task["dest"] = dest
        task["job_name"] = job_name
        file_task = FileTask(task)
        return_code = file_task.run(analyse_hosts, True)
    elif task["type"] == "script":
        local_script = ParamReplaceHandler.replace_param(task["local_script"], param_data)
        task["local_script"] = local_script
        script_task = ScriptTask(task)
        return_code = script_task.run(analyse_hosts, task, param_data, job_name, job_node_parallel=False,
                                      job_param_item=None)
    else:
        LOGGER.error("task type " + task["type"] + " is not supported.")
        return_code = 1

    if Constants.cur_task_num != 0:
        progress = round(float(Constants.cur_task_num) / float(Constants.task_num) * 100, 2)
        with open(Constants.TMP_SCRIPT_DIR + "/progress.txt", "w") as f:
            f.write(str(progress))
    end_time = time.time()
    total = end_time - start_time
    with open(Constants.TMP_SCRIPT_DIR + "/run_time.txt", "a+") as f11:
        tmp1 = task["name"] + ": " + str(total) + "\n"
        f11.write(tmp1)
    return return_code


def init_task_own_log_file(job_param, task_name):
    if job_param.get("task_log_file_own"):
        log_job_dir = LOG_JOB_DIR
        if "LOG_JOB_DIR" in PARAM_DATA:
            log_job_dir = PARAM_DATA["LOG_JOB_DIR"]
            if not os.path.exists(log_job_dir):
                os.makedirs(log_job_dir)
        log_file = "%s.log-%s" % (task_name, Constants.STR_TIME_STAMP)
        log_job_file = os.path.join(log_job_dir, log_file)
        LogUtils.setup_file_logger(TASK_LOGGER, log_job_file)


def generate_job_items(job_items, job_with_items):
    job_param_item = {}
    if job_items:
        for key, value in job_items.items():
            job_param_item[str(job_with_items + "." + key)] = value
    return job_param_item


def do_schedule():
    send_host_ip_list = []
    analyse_host = ALL_HOST
    if SCHEDULER_ARGS.host_conf:
        send_host_ip_list, analyse_host = HOST_PARSER.get_send_host_info(SCHEDULER_ARGS.send_host)
    else:
        send_host_ip_list = [i["ip"] for i in ALL_HOST]
    analyse_hosts = analyse_host or ALL_HOST
    if SCHEDULER_ARGS.command:
        # execute command
        scheduler_return_code = execute_command(analyse_hosts, SCHEDULER_ARGS.command, SCHEDULER_ARGS.time_out,
                                                True, SCHEDULER_ARGS.print_result,
                                                task_name=Constants.TASK_NAME_SEND_COMMAND)
    elif SCHEDULER_ARGS.source_file_path:
        # execute file
        if not SCHEDULER_ARGS.dest_path:
            PRINT_LOGGER.info("destination path can not be null")
            sys.exit(1)
        scheduler_return_code = execute_file(analyse_hosts, SCHEDULER_ARGS.source_file_path, SCHEDULER_ARGS.dest_path,
                                             SCHEDULER_ARGS.time_out, "job_name", SCHEDULER_ARGS.scp_out_mode, True,
                                             task_name=Constants.TASK_NAME_SEND_SOURCE_FILE)
    elif SCHEDULER_ARGS.script_local_path:
        script_local_path_all = ParamReplaceHandler.replace_param(SCHEDULER_ARGS.script_local_path, PARAM_DATA)
        script_local_path = SCHEDULER_ARGS.script_local_path.split()[0]
        # send local script to remote tmp dir
        execute_file(analyse_hosts, script_local_path, Constants.TMP_SCRIPT_DIR, SCHEDULER_ARGS.time_out, "job_name",
                     task_name=Constants.TASK_NAME_SEND_SOURCE_FILE)
        # execute script cmd
        script_name = script_local_path_all.split("/")[-1]
        script_cmd = script_name.replace(script_name, Constants.TMP_SCRIPT_DIR + "/" + script_name)
        scheduler_return_code = execute_command(analyse_hosts, script_cmd,
                                                SCHEDULER_ARGS.time_out, True, SCHEDULER_ARGS.print_result,
                                                task_name=Constants.TASK_NAME_EXECUTE_SCRIPT)
    else:
        scheduler_return_code = execute_jobs(send_host_ip_list)

    return scheduler_return_code


def save_recovery_info(job_md5, job_return_code, recovery_data, recovery_id):
    if SCHEDULER_ARGS.recovery:
        job_return_status = True if job_return_code == 0 else False
        recovery_data[recovery_id][job_md5] = job_return_status
        recovery_data[recovery_id]["timestamp"] = Constants.STR_TIME_STAMP


def do_recovery(job_md5, job_name, job_parser, recovery_data, recovery_id):
    if SCHEDULER_ARGS.recovery:
        if recovery_data.get(recovery_id):
            if recovery_data.get(recovery_id).get("job_file_md5") == job_parser.job_file_md5:
                if recovery_data.get(recovery_id).get(job_md5):
                    LOGGER.info(job_name + " job break because execute status is true.")
                    PRINT_LOGGER.info("    %s skip job because job execute status is ok"
                                      % LogUtils.LOG_INFO_OK)
                    status_info = {
                        "job": job_name,
                        "task": "",
                        "code": 0,
                        "skip": True,
                    }
                    result_status.append(status_info)
                    write_status()
                    return True
            else:
                PRINT_LOGGER.info("%s job file is modify, please check job file" % LogUtils.LOG_INFO_ERR)
                sys.exit(1)
        else:
            PRINT_LOGGER.info("%s RECOVERY_ID:%s not found, please check RECOVERY_ID"
                              % (LogUtils.LOG_INFO_ERR, recovery_id))
            sys.exit(1)
    return False


def get_analyse_hosts(job_host, send_host_ip_list, job_param):
    analyse_hosts = [Constants.LOCAL_HOST]
    job_host = ParamReplaceHandler.replace_param(str(job_host), PARAM_DATA)
    job_host = ParamReplaceHandler.replace_param(str(job_host), job_param)
    if SCHEDULER_ARGS.host_conf:
        # avoid the "local" mode execute in wrong logic.
        if job_host != Constants.LOCAL_HOST:
            _, analyse_hosts = HOST_PARSER.get_send_host_info(job_host.split(","))
            # if send_host_ip_list has any elements, the ips which found in send_host_ip_list
            # or analyse_hosts will execute the job.
            if send_host_ip_list:
                temp_analyse_hosts = []
                for temp_host in ALL_HOST:
                    if temp_host["ip"] in send_host_ip_list \
                            and temp_host not in analyse_hosts:
                        temp_analyse_hosts.append(temp_host)
                analyse_hosts.extend(temp_analyse_hosts)
    else:
        if job_host != Constants.LOCAL_HOST:
            analyse_hosts = []
            if send_host_ip_list:
                temp_analyse_hosts = []
                for temp_host in ALL_HOST:
                    if temp_host["ip"] in send_host_ip_list \
                            and temp_host not in analyse_hosts:
                        temp_analyse_hosts.append(temp_host)
                analyse_hosts.extend(temp_analyse_hosts)
    return analyse_hosts, job_host


def do_init_recovery_info(job_abs_path, job_file_md5):
    recovery_data = {}
    recovery_id = None
    if SCHEDULER_ARGS.recovery:
        if os.path.exists(Constants.RECOVERY_FILE) and not SCHEDULER_ARGS.force_reset_recovery:
            recovery_data = YamlUtils.load_yaml_file(Constants.RECOVERY_FILE)
            if recovery_data:
                # clear data writen in longer than 7days
                recovery_data = RecoveryInfoHandler.clear_recovery_data(recovery_data)
                if not SCHEDULER_ARGS.recovery_id:
                    recovery_info = RecoveryInfoHandler.get_recovery_info(job_file_name=job_abs_path)
                    if recovery_info:
                        recovery_id = recovery_info[0].get("recovery_id")
        if not recovery_id or not recovery_data:
            recovery_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, str(Constants.LOCAL_TIME_STAMP)))
            recovery_data[recovery_id] = {"timestamp": Constants.STR_TIME_STAMP,
                                          "job_file_md5": job_file_md5, "job_file_name": job_abs_path}
    return recovery_data, recovery_id


os.environ['SETUP_TOOLS_DIR'] = Constants.SETUP_TOOLS_DIR
GLOBAL_PARAM = {"SETUP_TOOLS_DIR": Constants.SETUP_TOOLS_DIR}
UNREADY_HOSTS = []


def init_logger():
    log_scheduler_file = LogUtils.get_log_file_name("LOG_SCHEDULER_PATH") or Constants.LOG_SCHEDULER_FILE
    log_job_file = LogUtils.get_log_file_name("LOG_JOB_PATH") or Constants.LOG_JOB_FILE
    # log_csv_file = LogUtils.get_log_file_name("LOG_CSV_PATH") or Constants.LOG_CSV_FILE
    # init scheduler log
    LogUtils.setup_file_logger(LOGGER, log_scheduler_file, fmt="%(asctime)s - %(levelname)s: %(message)s")
    # init job&task log
    LogUtils.setup_file_logger(TASK_LOGGER, log_job_file)
    # init CSV log
    # LogUtils.setup_file_logger(CSV_LOGGER, log_csv_file, fmt="%(message)s")
    # # add csv log header
    # CSV_LOGGER.info("TASK_NAME,HOST,STATUS,LOGS,DESC")


def do_query_host():
    if SCHEDULER_ARGS.host_conf and SCHEDULER_ARGS.do_query_ips:
        invalid_groups = list(set(SCHEDULER_ARGS.query_ips).difference(set(HOST_PARSER.hosts.keys())))
        if invalid_groups:
            PRINT_LOGGER.info("Find non-exist group name: %s" % invalid_groups)
        query_ips = HostInfoHandler.get_group_ips(SCHEDULER_ARGS.query_ips, HOST_PARSER.hosts)
        if query_ips:
            PRINT_LOGGER.info(json.dumps(query_ips, indent=4))
        sys.exit(0)


def do_modify_sshd_port():
    if SCHEDULER_ARGS.host_conf and SCHEDULER_ARGS.modify_port:
        PRINT_LOGGER.info("job: modify sshd port")
        if check_modify_host(HOST_PARSER.origin_yaml_data, SCHEDULER_ARGS.send_host):
            LOGGER.info("check modify host success, start modify the ssh port")
            _, analyse_modify_hosts = HOST_PARSER.get_send_host_info(SCHEDULER_ARGS.send_host)
            target_modify_host = analyse_modify_hosts or ALL_HOST
            target_modify_host = check_host_ready(target_modify_host)
            modify_port_return_code = exec_modify_sshd_port(SCHEDULER_ARGS.modify_port, target_modify_host)
            LOGGER.info("modify the sshd port finished, return code is %s" % modify_port_return_code)
            if modify_port_return_code == 0:
                PRINT_LOGGER.info("modify sshd port %s" % LogUtils.LOG_INFO_OK)
                LOGGER.info("start dump the modified info to yaml file [%s]" % SCHEDULER_ARGS.host_conf)
                modify_host_port(SCHEDULER_ARGS.send_host, str(SCHEDULER_ARGS.modify_port),
                                 HOST_PARSER.origin_yaml_data)
                YamlUtils.dump_yaml_file(HOST_PARSER.origin_yaml_data, SCHEDULER_ARGS.host_conf)
            else:
                PRINT_LOGGER.info("modify sshd port %s" % LogUtils.LOG_INFO_ERR)
                sys.exit(1)
        else:
            LOGGER.info("check modify host failed, please check your input.")
            PRINT_LOGGER.info("check modify host failed, please check your input.")
            sys.exit(1)
        sys.exit(0)


def write_status():
    with open(Constants.TMP_SCRIPT_DIR + "/run_status.json", 'w') as f1:
        f1.write(json.dumps(result_status) + "\n")


SCRIPT_PATH = ""
PARAM_DATA = {}
PRINT_LOGGER = logging.getLogger('print')
TASK_LOGGER = logging.getLogger('task')
LOGGER = logging.getLogger('root')
# CSV_LOGGER = logging.getLogger('csv')

if __name__ == '__main__':
    # init tmp dir
    os.system("mkdir -p " + Constants.TMP_SCRIPT_DIR)
    # parse arguments
    SCHEDULER_ARGS = parse_args()
    # init console log
    LogUtils.setup_console_logger(PRINT_LOGGER)
    LogUtils.csv_file = GLOBAL_PARAM.get("LOG_CSV_PATH") or Constants.LOG_CSV_FILE
    with open(LogUtils.csv_file, "a+") as f1:
        w = csv.writer(f1)
        # 写入列头
        w.writerow(["TASK_NAME", "HOST", "STATUS", "LOGS", "DESC"])

    PARAM_DATA.update({"LOCAL_IP": CommonUtils.get_local_ip()})
    # remove recovery data
    if SCHEDULER_ARGS.remove_recovery_data:
        RecoveryInfoHandler.do_remove_recovery_info()
    # get recovery data
    if SCHEDULER_ARGS.get_recovery_data:
        RecoveryInfoHandler.do_get_recovery_info(SCHEDULER_ARGS.recovery_job_file)
    # load param.yml
    param_file_list = SCHEDULER_ARGS.param_conf.split(",") if SCHEDULER_ARGS.param_conf else []
    for parm_file in param_file_list:
        PARAM_DATA.update(YamlUtils.load_yaml_file(parm_file))

    if SCHEDULER_ARGS.encrypt:
        for parm_file in param_file_list:
            PARAM_DATA.update(YamlUtils.load_yaml_file(parm_file))
            CommonUtils.encrypt_data(PARAM_DATA, "_PWD", SCHEDULER_ARGS.param_conf)
            # PARAM_DATA.update(decrypt_data(PARAM_DATA, "_PWD"))
            CommonUtils.decrypt_data(PARAM_DATA, "_PWD")
    ParamReplaceHandler.replace_param_param(PARAM_DATA)
    # merge yaml param and global param
    PARAM_DATA.update(GLOBAL_PARAM)

    if SCHEDULER_ARGS.pool_num == 0:
        PARAM_DATA.update({"cpu_num": multiprocessing.cpu_count()})
    else:
        PARAM_DATA.update({"cpu_num": SCHEDULER_ARGS.pool_num})

    # init scheduler and task logger and csv logger
    init_logger()

    if SCHEDULER_ARGS.script_path:
        SCRIPT_PATH = ParamReplaceHandler.replace_param(SCHEDULER_ARGS.script_path, PARAM_DATA)
        SCRIPT_PATH = SCRIPT_PATH.replace(",", ":")

    ALL_HOST = [Constants.LOCAL_HOST]
    ALL_GROUP_HOST = {}
    # parse host conf
    if SCHEDULER_ARGS.host == "":
        if SCHEDULER_ARGS.host_conf:
            HOST_PARSER = HostParser(SCHEDULER_ARGS.host_conf)
            if SCHEDULER_ARGS.encrypt:
                HOST_PARSER.encrypt()
            HOST_PARSER.decrypt()
            HOST_PARSER.parse()
            # if host.yml if empty, make ALL_HOST as ["local"]
            ALL_HOST = HOST_PARSER.all_hosts if HOST_PARSER.all_hosts else [Constants.LOCAL_HOST]
            ALL_GROUP_HOST = HOST_PARSER.all_group_hosts
            if "HOST" not in PARAM_DATA:
                PARAM_DATA.update({"HOST": ALL_HOST})
        else:
            PRINT_LOGGER.error("not found host.yml or -host params: ")
            sys.exit(1)
    else:
        host_info = SCHEDULER_ARGS.host.split(",")
        if len(host_info) != 4:
            PRINT_LOGGER.error("host format error: " + SCHEDULER_ARGS.host)
            sys.exit(1)
        else:
            ALL_HOST = [
                {'ip': host_info[0], 'password': host_info[2], 'group': [host_info[0]],
                 'port': host_info[3], 'user': host_info[1]}
            ]
            ALL_GROUP_HOST = {host_info[0]: [host_info[0]]}
            if "HOST" not in PARAM_DATA:
                PARAM_DATA.update({"HOST": ALL_HOST})
    # do query host
    do_query_host()
    # modify sshd port
    do_modify_sshd_port()
    if UNREADY_HOSTS:
        PRINT_LOGGER.info("unready hosts %s, will be skipped in following tasks." % UNREADY_HOSTS)

    # send setup-tools file
    if SCHEDULER_ARGS.send_file:
        # add local to ALL_HOST
        ALL_HOST_SEND = copy.deepcopy(ALL_HOST)
        RETURN_CODE = send_setup_tools_file(ALL_HOST_SEND, SCHEDULER_ARGS.time_out)
        if RETURN_CODE != 0:
            sys.exit(RETURN_CODE)

    PRINT_LOGGER.info("-----------------------------------------------")
    PRINT_LOGGER.info("------------------Summary----------------------")
    PRINT_LOGGER.info("-----------------------------------------------")
    SCHEDULER_RETURN_CODE = do_schedule()
    PRINT_LOGGER.info("-----------------------------------------------")
    if SCHEDULER_ARGS.display_table:
        if LogUtils.get_log_file_name("LOG_CSV_PATH"):
            CsvLogPrinter.csv_to_table(LogUtils.get_log_file_name("LOG_CSV_PATH"))
            print("Download File View Details: %s" % LogUtils.get_log_file_name("LOG_CSV_PATH"))
        else:
            CsvLogPrinter.csv_to_table(Constants.LOG_CSV_FILE)
            print("Download File View Details: %s" % Constants.LOG_CSV_FILE)
    sys.exit(SCHEDULER_RETURN_CODE)
