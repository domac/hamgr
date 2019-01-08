#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import json
import string
import shutil


#获取当前py文件所在的目录
def GetCurDir():
    dir = os.path.dirname(os.path.abspath(__file__))
    dir = dir.replace("\\", "/")
    return dir


# 变量
datFile = GetCurDir() + "/../server_config.dat"
templateFile = GetCurDir() + "/../template/supervisor_template.conf"
supervisor_base_dir = "/etc/supervisord.d"
supervisor_conf_dir = os.path.join(supervisor_base_dir, "pcmgr_conf")
LOG_PATH = "/data/logs/supervisor/supervisor_server_install.log"

if not os.path.exists("/data/logs/supervisor/"):
    os.mkdir("/data/logs/supervisor/")

# 日志处理
g_logger = logging.getLogger('mylogger')
g_logger.setLevel(logging.INFO)
fileLogHandler = logging.FileHandler(LOG_PATH)
fileLogHandler.setLevel(logging.INFO)
formatter = logging.Formatter(
    '[%(asctime)s][%(thread)d][%(filename)s][line: %(lineno)d][%(levelname)s] ## %(message)s'
)
fileLogHandler.setFormatter(formatter)
g_logger.addHandler(fileLogHandler)


def _byteify(data, ignore_dicts=False):
    if isinstance(data, unicode):
        return data.encode('utf-8')
    if isinstance(data, list):
        return [_byteify(item, ignore_dicts=True) for item in data]
    if isinstance(data, dict) and not ignore_dicts:
        return {
            _byteify(key, ignore_dicts=True): _byteify(
                value, ignore_dicts=True)
            for key, value in data.iteritems()
        }
    return data


def json_load_byteified(file_handle):
    return _byteify(
        json.load(file_handle, object_hook=_byteify), ignore_dicts=True)


def json_loads_byteified(json_text):
    return _byteify(
        json.loads(json_text, object_hook=_byteify), ignore_dicts=True)


#### 上面是日志器的初始化, 不是主要逻辑 ######


def find_string(s, t):
    try:
        string.index(s, t)
        return True
    except ValueError, e:
        g_logger.error(e)
        return False


def reflash_conf_dir():
    try:
        g_logger.info("reflash supervisor config files")

        if not os.path.exists(supervisor_base_dir):
            os.mkdir(supervisor_base_dir)

        # 如果目录已经存在,删除历史记录
        if os.path.exists(supervisor_conf_dir):
            shutil.rmtree(supervisor_conf_dir)
        os.mkdir(supervisor_conf_dir)
    except Exception, e:
        g_logger.error(e)
    return supervisor_conf_dir


# 加载服务配置数据
def load_server_config_dat(datFile):
    g_logger.info("load server_config_dat")

    result_dict = dict()
    try:
        with open(datFile, 'r') as load_f:
            json_dict = json_load_byteified(load_f)

        if not json_dict:
            g_logger.error("no server config data read")

        processes_dict = json_dict["processes"]

        for processes_item in processes_dict:
            start = processes_item.get("start") or ""
            mode = processes_item.get("mode") or 0

            if find_string(start, "tools\\") or mode != 2:
                continue

            # 规范linux字符串
            start = start.replace("\\", "/")
            start = start.replace(".exe", "")
            processes_item["start"] = start

            # 获取基本数据
            server_name = os.path.basename(start)
            server_path = start

            result_dict[server_name] = server_path
    except IOError, e:
        g_logger.error(e)

    return result_dict


def load_template(filepath):
    g_logger.info("load supervisor template %s" % filepath)
    template_str = ""
    try:
        with open(filepath, 'r') as temp_file:
            template_str = temp_file.read()
    except Exception, e:
        g_logger.error(e)
    return template_str


def writeTo(conf_dir, server_name, server_tampleate_info):
    config_file = os.path.join(conf_dir, server_name + ".conf")
    g_logger.info("start supervisor conf file : %s " % config_file)
    try:
        with open(config_file, "w") as cf:
            cf.write(server_tampleate_info)
    except Exception, e:
        g_logger.error(e)
        return
    g_logger.info("finish supervisor conf file : %s " % config_file)


def create_supervisor_server_configs(templateFile, serverdict={}):

    server_config_str = load_template(templateFile)

    conf_dir = reflash_conf_dir()

    for server_name, server_path in serverdict.items():
        server_temp = server_config_str
        server_temp = server_temp.replace('${server_name}', server_name)
        server_temp = server_temp.replace('${server_path}', server_path)
        writeTo(conf_dir, server_name, server_temp)


if __name__ == "__main__":
    g_logger.info("supervisor servers setup")
    servers = load_server_config_dat(datFile)
    create_supervisor_server_configs(templateFile, servers)
