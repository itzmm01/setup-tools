# 私有化产品交付工具集

如果您使用接入，推荐使用feature/1.2版本

如果要进行开源贡献，目前开发到1.2分支，您贡献代码可以往feature/1.2提交

## 1 项目介绍
setup-tools是私有化场景交付下的通用能力的工具集合。
致力于解决产品私有化场景下全流程的辅助工具。
目前已接入的私有化产品包括：
1、腾讯会议
2、TCS
3、里约网关
4、TKE
5、TiMatrix

常见的交付流程包括
![image.png](/uploads/44B8106EAC204DB8A23F7BABBE7301B9/image.png)


目前工具架构图如下图
![图片](/uploads/A778A4083BD14E36ADD96BD00A233ABD/图片)



## 2 快速上手

请搜索setup-tools-doc项目


## 3 模块说明

| **模块名称**   | **详述** |
|----------------|--------------|
| 通用工具       |提供场景的工具能力|
| 管控工具       |提供从一台机器向目标机器分发命令和分发文件的能力|
| 环境检查       |提供基础的环境检查原子项脚本|
| 环境初始化     |提供系统环境参数修改、补包等能力|
| 指标采集       |提供原子的环境监控项|
| 日志收集       |提供日志搜索功能|
| 作业编排工具   |定义作业模板实现作业编排与分发|
| 规划工具       |Web版的交付配置规划工具|
| 命令行         |可交互式的命令行工具|


### 4 目录结构

包结构定义如下
```bash
|-   check   环境检查项
|-   cli.sh cli命令集
|-   common  通用工具
|-   init    环境初始化
|-   logcollect 日志收集
|-   monitor  指标采集
|-   planning 配置规划
|-   rpms    工具依赖库文件
|-   scheduler 作业编排工具、管控工具
|-   tools   通用工具集成
|-   test    常用场景测试用例
```

## 5 开发说明

### 编码规范
[1. shell编码规范](../standards-shell)
[2. python编码规范](../../standards/python)


开发前准备：
```
yum -y install epel-release python-pip python3
yum -y install ShellCheck
pip install pre-commit
git clone https://xxx/setup-tools.git
cd setup-tools
pre-commit install
```


## 6 行为准则
1、开发人员需要先fork个人分支，在个人分支上进行开发
2、提交代码时，需要加comment备注，提交类型参考如下：
* **minor**: 普通修改
* **bugfix**: bug修复
* **feature**: 增加特性

3、开发完成后，提交merge request到dev分支，审核人填写相应仓库管理员
4、后续由专人进行统一版本管理

## 7 发布规范

1、对master分支代码的每一次发布必须标记版本号tag
2、tag命名规则：```主版本号.次版本号.修订号```，如```1.1.11```。(遵循[语义化版本命名规范](https://semver.org/lang/zh-CN/))

## 8 如何加入
 请联系对应支撑人员
## 9 常见问题 

## 10 团队介绍

