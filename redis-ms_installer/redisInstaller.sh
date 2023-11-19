#!/bin/bash
INSTALLER_HOME=`pwd`
CONFIG_FILE=$INSTALLER_HOME/config.ini
REDIS_SRC_DIR=$INSTALLER_HOME/src
REDIS_AUTH_PASSWORD=

#Common configuration
REDIS_INSTALL_DIR=
REDIS_PKG_NAME=
REDIS_CONF_DIR=
REDIS_LOG_DIR=
REDIS_DATA_DIR=

#Master configuration
REDIS_MASTER_HOSTS=
REDIS_MASTER_USER=
REDIS_MASTER_GROUP=
REDIS_MASTER_PASSWORD=
REDIS_MASTER_CONFI=
REDIS_MASRER_PORT=

#Slave configuration
REDIS_SLAVE_HOSTS=
REDIS_SLAVE_USER=
REDIS_SLAVE_GROUP=
REDIS_SLAVE_PASSWORD=
REDIS_SLAVE_CONFI=
REDIS_SLAVE_PORT=


if [[ $# -eq 0 ]]
then
		echo -e "Usage: $0 -f [config file]"
		exit
fi

while getopts "f:" opt
do
		case $opt in
				f)
						CONFIG_FILE=$OPTARG
						;;
				?)
						echo
						;;
		esac
done

function getCommonConfig()
{
		REDIS_INSTALL_DIR=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'install_dir'/{print $2}' $CONFIG_FILE`
		REDIS_PKG_NAME=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'pkg_name'/{print $2}' $CONFIG_FILE`
		REDIS_CONF_DIR=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'conf_dir'/{print $2}' $CONFIG_FILE`
		REDIS_LOG_DIR=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'log_dir'/{print $2}' $CONFIG_FILE`
		REDIS_DATA_DIR=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'data_dir'/{print $2}' $CONFIG_FILE`
		REDIS_AUTH_PASSWORD=`awk -F ':' '/\['common'\]/{a=1}a==1&&$1~/'auth_password'/{print $2}' $CONFIG_FILE`

}

function getMasterConfig()
{
		REDIS_MASTER_HOSTS=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'hosts_master'/{print $2}' $CONFIG_FILE`
		REDIS_MASTER_USER=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'user_master'/{print $2}' $CONFIG_FILE`
		REDIS_MASTER_GROUP=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'group_master'/{print $2}' $CONFIG_FILE`
		REDIS_MASTER_PASSWORD=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'password_master'/{print $2}' $CONFIG_FILE`
		REDIS_MASTER_CONF=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'conf_file_master'/{print $2}' $CONFIG_FILE`
		REDIS_MASTER_PORT=`awk -F ':' '/\['master'\]/{a=1}a==1&&$1~/'port_master'/{print $2}' $CONFIG_FILE`
}

function getSlaveConfig()
{
		REDIS_SLAVE_HOSTS=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'hosts_slave'/{print $2}' $CONFIG_FILE`
		REDIS_SLAVE_USER=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'user_slave'/{print $2}' $CONFIG_FILE`
		REDIS_SLAVE_GROUP=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'group_slave'/{print $2}' $CONFIG_FILE`
		REDIS_SLAVE_PASSWORD=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'password_slave'/{print $2}' $CONFIG_FILE`
		REDIS_SLAVE_CONF=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'conf_file_slave'/{print $2}' $CONFIG_FILE`
		REDIS_SLAVE_PORT=`awk -F ':' '/\['slave'\]/{a=1}a==1&&$1~/'port_slave'/{print $2}' $CONFIG_FILE`
}

function slaveConfigGen()
{

		touch $INSTALLER_HOME/conf/redis-slave.conf

		cat > $INSTALLER_HOME/conf/redis-slave.conf << EOF
bind 0.0.0.0
port $REDIS_SLAVE_PORT
daemonize yes
protected-mode no
slaveof $REDIS_MASTER_HOSTS $REDIS_MASTER_PORT
requirepass $REDIS_AUTH_PASSWORD
masterauth $REDIS_AUTH_PASSWORD
dir $REDIS_INSTALL_DIR
logfile $REDIS_LOG_DIR/slave-6379.log
appendonly yes
appendfilename "slave.aof"
appendfsync everysec
#maxmemory #建议设置为物理内存的70%
maxmemory-policy volatile-lfu
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
tcp-backlog 511
tcp-keepalive 300
ignore-warnings ARM64-COW-BUG
EOF

}

function masterConfigGen()
{
		touch $INSTALLER_HOME/conf/redis-master.conf
		cat > $INSTALLER_HOME/conf/redis-master.conf << EOF
bind 0.0.0.0
port $REDIS_MASTER_PORT
daemonize yes
protected-mode no
requirepass $REDIS_AUTH_PASSWORD 
masterauth $REDIS_AUTH_PASSWORD 
dir $REDIS_INSTALL_DIR
logfile $REDIS_LOG_DIR/master-6379.log
appendonly yes
appendfilename "master.aof"
appendfsync everysec
#maxmemory #建议设置为物理内存的70%
maxmemory-policy volatile-lfu
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
tcp-backlog 511
tcp-keepalive 300
ignore-warnings ARM64-COW-BUG 
EOF
}

#获取配置信息
getCommonConfig 
getMasterConfig
getSlaveConfig 

#生成配置文件
masterConfigGen
slaveConfigGen



#SLAVE节点创建相关目录并安装Redis
for i in $REDIS_SLAVE_HOSTS
do
	sshpass -p $REDIS_SLAVE_PASSWORD scp $REDIS_SRC_DIR/$REDIS_PKG_NAME $USER@$i:/tmp
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:上传源码文件失败"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "rm -r /tmp/redis-release"
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "mkdir -p /tmp/redis-release"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:tmp/redis-release目录创建失败"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S rm -r $REDIS_INSTALL_DIR"
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S mkdir -p $REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_INSTALL_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S rm -r $REDIS_CONF_DIR"
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S mkdir -p $REDIS_CONF_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_CONF_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S rm -r $REDIS_LOG_DIR"
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S mkdir -p $REDIS_LOG_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_LOG_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S rm -r $REDIS_DATA_DIR"
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S mkdir -p $REDIS_DATA_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_DATA_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "tar -xvf /tmp/$REDIS_PKG_NAME -C /tmp/redis-release --strip-components=1"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:解压源码包失败"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "cd /tmp/redis-release;make -j8;sudo -S make install PREFIX=$REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR::$i:编译失败"
			exit
	fi
	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "sudo -S chown $REDIS_SLAVE_USER.$REDIS_SLAVE_GROUP -R $REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:更改目录用户及用户组权限失败"
			exit
	fi

done

#上传Redis配置文件至SLAVE节点并且启动Redis
for i in $REDIS_SLAVE_HOSTS
do
	sshpass -p $REDIS_SLAVE_PASSWORD scp $INSTALLER_HOME/conf/$REDIS_SLAVE_CONF $REDIS_SLAVE_USER@$i:$REDIS_CONF_DIR
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:上传配置文件失败"
			exit
	fi

	sshpass -p $REDIS_SLAVE_PASSWORD ssh $REDIS_SLAVE_USER@$i "$REDIS_INSTALL_DIR/bin/redis-server $REDIS_CONF_DIR/$REDIS_SLAVE_CONF"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:启动redis实例失败"
			exit
	fi

done


for i in $REDIS_MASTER_HOSTS
do
	sshpass -p $REDIS_MASTER_PASSWORD scp $REDIS_SRC_DIR/$REDIS_PKG_NAME $REDIS_MASTER_USER@$i:/tmp
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:150:上传源码文件失败"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "rm -r /tmp/redis-release"
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "mkdir -p /tmp/redis-release"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:tmp/redis-release目录创建失败"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S rm -r $REDIS_INSTALL_DIR"
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S mkdir -p $REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_INSTALL_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S rm -r $REDIS_CONF_DIR"
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S mkdir -p $REDIS_CONF_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_INSTALL_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S rm -r $REDIS_LOG_DIR"
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S mkdir -p $REDIS_LOG_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_INSTALL_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S rm -r $REDIS_DATA_DIR"
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S mkdir -p $REDIS_DATA_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:$REDIS_INSTALL_DIR目录创建失败，请检查用户是否有足够的权限，或检查用户是否能够免密执行sudo，如不能，请为用户配置免密执行sudo权限"
			exit
	fi

	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "tar -xvf /tmp/$REDIS_PKG_NAME -C /tmp/redis-release --strip-components=1"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:解压源码包失败"
			exit
	fi
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "cd /tmp/redis-release;make -j8;sudo -S make install PREFIX=$REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR::$i:编译失败"
			exit
	fi
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "sudo -S chown $REDIS_MASTER_USER.$REDIS_MASTER_GROUP -R $REDIS_INSTALL_DIR"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:更改目录用户及用户组权限失败"
			exit
	fi

done

#上传Redis配置文件至MASTER节点并且启动Redis
for i in $REDIS_MASTER_HOSTS
do
	sshpass -p $REDIS_MASTER_PASSWORD scp $INSTALLER_HOME/conf/$REDIS_MASTER_CONF $REDIS_MASTER_USER@$i:$REDIS_CONF_DIR
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:上传配置文件失败"
			exit
	fi
	sshpass -p $REDIS_MASTER_PASSWORD ssh $REDIS_MASTER_USER@$i "$REDIS_INSTALL_DIR/bin/redis-server $REDIS_CONF_DIR/$REDIS_MASTER_CONF"
	if [[ $? -ne 0 ]]
	then
			echo -e "ERROR:$i:启动Redis实例失败"
			exit
	fi

done

