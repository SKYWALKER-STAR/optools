> 创建日期:2023/11/14
> 最后修改日期:2023/11/14
> 作用:Nginx一键部署脚本README文件

#### I 介绍
---
  该脚本是Nginx一键部署脚本

  该脚本默认的编译选项有:
        - "--with-debug"
        - "--with-http_ssl_module"
        - "--with-http_stub_status_module"
        - "--with-http_v2_module"
  默认添加的模块有:
        - "nginx-module-vts-0.2.2"
        - "echo-nginx-module-master"
        - "nginx-http-concat-master"

  默认的Nginx版本是1.20.2

  用户可以通过config.ini文件自定义编译选项及模块

#### II 文件及目录
---

-nginxInstaller.sh: Nginx 一键安装脚本，具体使用方式见第三小节。

-config.ini: 安装脚本的配置文件，用户可以通过编辑该文件来指定Nginx的编译选项以及添加第三方模块。具体配置文件的格式及使用方式见第四小节

-modules: 该目录下放置用户需要增加的Nginx第三方模块。所有第三方模块必须解压后再放置在该目录中。

-src: 该目录用来放置Nginx源码包。该目录中只允许存在唯一一个源码包。

#### III 使用方式 
---
nginxInstaller.sh有两种启动方式

1. 直接运行 ./nginxInstaller.sh,启动脚本会读取config.ini配置文件以获取Nginx编译选项。

2. ./nginxInstaller.sh -f 【配置文件】。通过 -f 选项指定配置文件。

3. 该安装脚本默认将Nginx安装在服务器/data/software/nginx目录下，并且监听443、80端口,因此在运行该脚本前，请确保443、80端口没有被占用。

4. 该安装脚本使用到tar、yum、unzip工具，运行前请确保服务器上这几个工具可用,并且确保服务器配置了合适的yum源。

5. 该脚本默认将Nginx安装在/data/software/nginx目录下。

#### IV 配置文件的使用
---
该脚本默认的配置文件为config.ini,配置文件的格式为:

[config]

options:'Nginx编译选项'

modules:'模块目录名称'

其中
  options选项后面是Nginx的编译选项，例如"--with-debug
  modules选项指定用户想要增加的模块，例如"nginx-http-concat-master',模块的名称为模块源码包解压后的相对路径的目录名称。在配置文件中指定了模块的名称后，需要将解压后的模块放置到modules目录中。
