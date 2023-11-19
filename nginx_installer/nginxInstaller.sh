#!/bin/bash
INSTALLER_HOME=`pwd`
OPTIONS="--with-debug --with-http_ssl_module --with-http_stub_status_module --with-http_stub_module --with-http_v2_module"
ADD_MOD="--add-module="

CONFIG_FILE=$INSTALLER_HOME/config.ini
NGINX_SRC_DIR=$INSTALLER_HOME/src
NGINX_DEP_DIR=$INSTALLER_HOME/deps
NGINX_MOD_DIR=$INSTALLER_HOME/modules
NGINX_COMPILE_DIR=nginx-release
NGINX_INSTALL_DIR=/data/software/nginx
NGINX_COMPILE_MOD=

NGINX_SRC_PKG=
EXTERN_MODULES=

if [[ `id -u` -ne 0 ]];
then
		echo -e "ERRPR:请以root身份执行该脚本"
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


#安装必要的依赖
sudo yum install -y gcc gcc-c++ pcre-devel openssl-devel zlib-devel perl-IPC-Cmd

function ReadINIfilePrefix()
{
		rv=`awk -F ':' '/\['config'\]/{a=1}a==1&&$1~/'options'/{print $2}' $CONFIG_FILE`
		OPTIONS=$rv
}	

function ReadINIfileModules()
{
		rv=`awk -F ':' '/\['config'\]/{a=1}a==1&&$1~/'module'/{print $2;}' $CONFIG_FILE`
		EXTERN_MODULES=${rv//\'/ }
}

ReadINIfileModules
for i in $EXTERN_MODULES
do
		NGINX_COMPILE_MOD=$NGINX_COMPILE_MOD$ADD_MOD$INSTALLER_HOME/modules/$i" "
done

#读取配置文件，获取Nginx的编译选项
if [[ $1 != "-default" ]]
then
		OPTIONS=NULL
		ReadINIfilePrefix
		OPTIONS=${OPTIONS//\'/}
fi

#创建Nginx安装目录
mkdir -p $NGINX_INSTALL_DIR

#只允许src目录中只有一个Nginx源码包
SRC_NUMBER=`ls $NGINX_SRC_DIR | wc -l`
if  [[ $SRC_NUMBER  -ne 1 ]]
then
		echo -e "ERROR: 请保证 $NGINX_SRC_DIR 目录中只有一个Nginx源码包"
		exit
else
		NGINX_SRC_PKG=`ls $NGINX_SRC_DIR`
fi

#根据压缩包的后缀来选择解压的工具
extension=$(rev <<< $NGINX_SRC_PKG | cut -d . -f1 | rev)
pushd $NGINX_SRC_DIR
mkdir -p $NGINX_COMPILE_DIR
case $extension in
gz | tar)
	tar -xvf $NGINX_SRC_PKG -C $NGINX_COMPILE_DIR --strip-components=1
	;;
zip)
	unzip $NGINX_SRC_PKG -d $NGINX_SRC_DIR/nginx-release
	;;
*)
	echo -e "ERROR: 无法识别的文件后缀"
	;;
esac
popd

NGINX_OPTIONS=$OPTIONS" "$NGINX_COMPILE_MOD

#解压后进入Nginx源码目录进行编译及安装
pushd $NGINX_SRC_DIR/$NGINX_COMPILE_DIR
CONFIG_CMD=`find . -name configure`
$CONFIG_CMD --prefix=$NGINX_INSTALL_DIR $NGINX_OPTIONS 
make -j8
if [[ $? -ne 0]]
then
echo -e "ERROR:编译出错"
exit
fi

make install 
if [[ $? -ne 0]]
then
echo -e "ERROR:安装出错"
exit
fi

popd

#加入SSL证书配置
mkdir -p $NGINX_INSTALL_DIR/conf/ssl
openssl req -x509 -newkey rsa:4096 -nodes -keyout $NGINX_INSTALL_DIR/conf/ssl/server.key -out $NGINX_INSTALL_DIR/conf/ssl/server.crt -sha256 -days 3650  -subj "/C=CN/ST=Beijing/L=Beijing/O=Alididi/OU=Ops/CN=*.qnapclub.eu"

#修改Nginx配置
cp -ra $NGINX_INSTALL_DIR/conf/nginx.conf $NGINX_INSTALL_DIR/conf/nginx.conf-origin
cat > $NGINX_INSTALL_DIR/conf/nginx.conf << "EOF"
user root;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    use epoll;
    worker_connections  65535;
 }


http {
    include       mime.types;
    default_type  application/octet-stream;
    vhost_traffic_status_zone;


    log_format  main  '$remote_addr | [$time_local] | $host | "$request" | '
                      '$status | $body_bytes_sent | "$http_referer" | '
                      '"$http_user_agent" | "$http_x_forwarded_for" | '
                      '$upstream_addr | $upstream_status | $upstream_response_time | '
                      '$server_addr | $request_time';

    log_format  log_json  '{ "remote_addr": "$remote_addr", '
                          '"time_local": "$time_local", '
                          '"host": "$host", '
                          '"request": "$request", '
                          '"status": "$status", '
                          '"body_bytes_sent": "$body_bytes_sent", '
                          '"http_referer": "$http_referer", '
                          '"http_user_agent": "$http_user_agent", '
                          '"http_x_forwarded_for": "$http_x_forwarded_for", '
                          '"upstream_addr": "$upstream_addr", '
                          '"upstream_status": "$upstream_status", '
                          '"upstream_response_time": "$upstream_response_time", '
                          '"server_addr": "$server_addr", '
                          '"request_time": "$request_time", '
                          '}';

    access_log  $NGINX_INSTALL_DIR/logs/access_json.log  log_json;
    access_log  $NGINX_INSTALL_DIR/logs/access.log  main;

    sendfile        on;
    server_tokens off;
    #keepalive_timeout  0;
    keepalive_timeout  65;
    keepalive_requests 10000;

    gzip  on;
	server {
	    listen 443 ssl;
	    ssl_certificate  $NGINX_INSTALL_DIR/conf/ssl/server.crt;
	    ssl_certificate_key $NGINX_INSTALL_DIR/conf/ssl/server.key;
        #ssl_stapling on;
        #ssl_stapling_verify on;
        #ssl_trusted_certificate $NGINX_INSTALL_DIR/conf/ssl/server.crt;
	    proxy_connect_timeout 120s;
	    proxy_read_timeout 200s;
	    ssl_protocols TLSv1.2 TLSv1.3;
	    ssl_prefer_server_ciphers on;
	    ssl_session_tickets on;
	    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE;
	    large_client_header_buffers 8 16k;
	    ssl_session_cache shared:SSL:20m;
	    ssl_session_timeout  1h;
	    proxy_ignore_client_abort on;

        location /nginx_status {
            stub_status;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }

    }


    server {
       listen 80;
       location /nginx_status {
           stub_status;
           access_log off;
           allow 127.0.0.1;
           deny all;
       }
    }
}

EOF

#启动Nginx
$NGINX_INSTALL_DIR/sbin/nginx
