> Author: ming

> Create Date: 2023/10/25

> LastModify Date: 2023/10/25

### I 介绍
---
1. 该脚本的作用是从指定的主机上拉取指定的文件到本地/tmp目录下，然后再分发到指定的远程主机上，分发到远程主机上的存储位置可自定义。

2. 该脚本通过config.ini文件指定主机信息。有关编写config.ini文件的内容，请参考《II.config.ini》

### II.config.ini
---
1. config.ini是脚本默认的配置文件，用户在其中指定拉取文件的主机和分发文件的主机。

2. config.ini文件中的主机类型分为两类，一类为要拉取的文件所在的主机，一类为待分发文件的主机，它们的配置书写基本格式如下:

3. 要拉取的文件所在的主机
	`
	[OriginHost] 

	ip=ip地址 

	port=ssh端口号 

	user=用户名 

	filepath=要拉去的文件的绝对路径 

	filname=要拉取得文件名 
	`

4. 待分发文件的主机 
	`
	[HostName] 

	ip=ip地址 

	port=端口号 

	user=远程用户 

	storepath=远程主机存储文件的位置 
	`

5. 以上所列为必须的配置项，其中，要拉取的文件所在的主机的名称必须为[OriginHost]，待分发文件的主机的名称可自定义。

### III.选项
---
1. -h 打印帮助内容 

2. -f 指定配置文件内容，如不增加该选项，则默认为./config.ini

### IV.启动与使用
---
1. git clone git@github.com:SKYWALKER-STAR/optools 

2. 进入optools/dits目录，执行python3 distribute.py ( -f [配置文件])
