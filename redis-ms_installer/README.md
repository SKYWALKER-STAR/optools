> 创建日期:2023/11/17

> 最后修改日期:2023/11/17

> 用途: Redis主从部署Readme文件

#### 目录
---
  I.总览
  II.启动方式
  III.文件及目录说明
  IV.配置文件的使用方法
  V.错误输出格式

#### I 总览
---
  该脚本是redis主从部署脚本，以下列出该部署脚本的部分默认值:

  1. 默认的部署路径为:/data/software/redis

  2. 默认的redis版本为 7.0.12

  3. 默认的架构为一主二从，主节点监听在6379端口，从节点监听在6380端口

  4. 脚本默认读取的配置文件为config.ini,用户可以编辑该文件自定义安装部署的某些内容,具体的格式说明请参见第四小节

  执行脚本前，请检查:

  1. 所有涉及的服务器之间是否可通信

  2. 目标服务器是否配置了可用的yum源，该脚本通过yum检查redis必要的依赖是否已经安装

  3. 配置文件中的登录用户是否有root权限，是否能够免密提权。详细信息请参考第四小节

#### II 启动方式
---

  1. 启动命令: ./redisInstaller.sh -f [配置文件] ,其中-f选项是必须的

#### III 文件及目录说明
---

  1. -src:放置Redis源码包的位置，目前仅支持tar包

  2. -conf:redis配置文件生成后，可以在该目录下找到相关的配置文件,请勿手动修改该目录的内容

  3. -redisInstaller.sh:启动脚本

  4. -config.ini:安装脚本的配置文件

#### IV 配置文件的使用方法
---
  1. 配置文件仅支持以下关键字:

      common:
         install_dir:
         pkg_name:
         conf_dir:
         log_dir:
         data_dir:
         auth_password:

      master:
         hosts_master:
         user_master:
         group_master:
         pasword_master:
         conf_file_master:
         port_master:

      slave:
         hosts_slave:
         user_slave:
         group_slave:
         password_slave:
         conf_file_slave:
         port_slave:

    具体格式请参考$INSTALLER_HOME/config.ini文件内容

  2. 详细解释:

     -common: 该关键字下的配置项是通用的配置项，例如安装目录、源码包名称。所有服务器上的这些选项都是一致的。

       -install_dir: 安装redis的目标目录,默认为/data/software/redis

       -pkg_name: redis源码包的名称，该名称应该与src目录下的源码包名称相对应,默认为redis-7.0.12.tar.gz

       -conf_dir: 安装完成后，redis配置文件所在的目录,默认为/data/software/redis/conf

       -log_dir: 安装完成后，redis日志所在的路径,默认为/data/software/redis/logs

       -data_dir: 安装完成后，redis数据文件所在的路径，默认为/data/software/redis/data

       -auth_password: redis登录验证密码,默认为 password

     -master: 该关键字下的配置是所有主节点共用的配置
     
        -hosts_master: 将要运行redis主节点的服务器地址，该选项可以有多个，默认指定一个IP为主节点

        -user_master: ssh登录hosts_master指定的服务器的用户,该用户需要具有root权限，并且能够免密执行sudo命令

        -gorup_master: hosts_master指定的服务器的用户组

        -password_master: user_master的密码

        -confi_file_master: redis主节点配置文件的名称,默认为redis-master.conf

     -slave: 该关键字下的配置是所有从节点共用的配置
     
        -hosts_slave: 指定要运行redis从节点的服务器地址，该选项可以有多个，默认指定两个从节点

        -user_slave: ssh登录hosts_slave指定的服务器的用户,该用户需要具有root权限，并且能够免密执行sudo命令

        -group_slave: hosts_slave指定的服务器的用户组

        -password_slave: user_slave的密码

        -confi_file_slave: redis从节点配置文件的名称,默认为redis-slave.conf

#### V 错误输出格式
---

ERROR:【出现错误的IP】:错误内容
