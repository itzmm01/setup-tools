## 网络检查工具使用

### 1 工具介绍
此网络检查工具，基于iperf3实现，通过该工具，对机器间网络环境进行检查，
包括丢包率、上下行带宽、网络抖动等指标的检查。结合setup-tools进行使用，
将网络检查项通过编排任务的方式去执行，无需繁琐的手动操作，实现一键式的检查


### 2 目录结构

工具目录结构如下
```bash
|-   dependencies   工具的依赖，如rpm等
|-   init-start-iperf-server.sh   启动iperf服务端脚本
|-   init-stop-iperf-server.sh   停止iperf服务端脚本
|-   check-network-by-iperf.sh   使用iperf进行网络检查脚本
|-   host.yml  编排作业host配置文件
|-   param.yml 编排作业参数配置文件
|-   job-check-ping.yml 检查网络连通性作业文件
|-   job-init-iperf.yml 初始化安装iperf工具作业文件
|-   job-check-loss.yml 检查机器间网络丢包率作业文件
|-   job-check-bandwidth-upload.yml 检查机器间上行带宽作业文件
|-   job-check-bandwidth-download.yml 检查机器间下行带宽作业文件
|-   job-check-delay.yml 检查机器间网络抖动作业文件
|-   job-run-perf-server.yml 启动iperf服务作业文件
|-   job-kill-perf-server.yml 停止iperf服务作业文件
|-   README.md  工具说明文档
```

### 3 工具使用

使用前准备：
```
1.获取最新的setup-tools交付工具集,进入到根目录
2.根据实际情况，修改tools/network/iperf/目录下host.yml、params.yml等配置项
3.进入到setup-tools根目录，执行source cli.env，初始化编排工具使用环境
```

工具使用：

```
进入到setup-tools根目录，根据检测场景，使用不同的编排命令

1.通过ping命令检查网络连通性
cli scheduler -c tools/network/iperf/job-check-ping.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml

2.初始化安装iperf3组件
cli scheduler -c tools/network/iperf/job-init-iperf.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml

3.检查机器间网络丢包率  
cli scheduler -c tools/network/iperf/job-check-loss.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml -pr y

4.检查机器间上行带宽
cli scheduler -c tools/network/iperf/job-check-bandwidth-upload.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml -pr y

5.检查机器间下行带宽
cli scheduler -c tools/network/iperf/job-check-bandwidth-download.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml -pr y

6.检查机器间网络抖动
cli scheduler -c tools/network/iperf/job-check-delay.yml -i tools/network/iperf/host.yml -p tools/network/iperf/param.yml -pr y

注：如果不是在setup-tools根目录下执行cli scheduler命令，请将相应的yml文件路径指定为实际路径
```

### 4 常见错误解决方案

#### 1.初始化iperf3组件时，报错如下图
![rpm-error.png](rpm-error.png)
```
由RPM库损坏引起，执行如下命令重建RPM库即可
cd /var/lib/rpm && rm -rf __db && rpm --rebuilddb
```

### 4 问题反馈与支撑
 请联系setup-tools交付工具集接口人


