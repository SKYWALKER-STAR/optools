#######################################################
#Author: ming
#Create Date: 2023/10/25
#LastModify Date: 2023/10/25
#Usage: 该脚本的作用是分发文件。将一台指定主机上的文件
#	下载到本地/tmp/目录下，然后再根据config.ini文件
#	中的信息分发到制定的远程主机的指定目录下。具体
#	信息请参见ReadME.md
#######################################################

#*coding=utf-8

import os
import argparse
import configparser

#从远程主机获取文件并存储在本地localstore位置
#dport: 远程主机端口
#duser: 远程主机用户
#dip: 远程主机ip
#dfilepath: 远程主机上文件路径,该路径必须是绝对路径
#localstore: 文件下载后在本地的存储路径
def scp_get(dport,duser,dip,dfilepath,localstore):
	cmd = "scp -P {dest_port} {dest_user}@{dest_ip}:{dest_filepath} {local_store}".format(dest_port=dport,
										dest_user=duser,
										dest_ip=dip,
										dest_filepath=dfilepath,
										local_store=localstore)
	return cmd

#将本地文件filesend传输到远程主机上,需要在remoteINFO中指定远程主机存储文件的位置
#dport: 远程主机端口
#duser: 远程主机用户
#dip: 远程主机ip
#dfilepath: 远程主机上存储文件的路径,该路径必须是绝对路径
#localfile: 希望传输的本地文件路径，该路径必须是绝对路径
def scp_put(dport,duser,dip,dfilepath,localfile):
	cmd = "scp -P {dest_port} {local_file} {dest_user}@{dest_ip}:{dest_filepath}".format(dest_port=dport,
										dest_user=duser,
										dest_ip=dip,
										dest_filepath=dfilepath,
										local_file=localfile)
	return cmd

#根据host信息构建远程主机的信息,并且返回一个列表
#config: config对象
def iniHostInformation(config):
	for i in config.sections():
		hostInfo = {}
		for j in config.options(i):
			hostInfo['Name'] = i
			hostInfo[j] = config[i][j]
		yield hostInfo

#获取远程主机列表
#config: config对象
def getHostList(config):
	hostList = []
	for i in iniHostInformation(config):
		hostList.append(i)

	return hostList

#获取配置文件
def getConfig(configfile="./config.ing"):
	con = configparser.ConfigParser()
	con.read(configfile,encoding='utf-8')
	return con
	
def main(configfile="./config.ini"):

	originHost = {}
	fileName = None
	con = getConfig(configfile)
	hostList = getHostList(con)

	for i in hostList:
		if i['Name'] == 'OriginHost':
			originHost = i
			fileName=i['filename']
			break;

	os.system(scp_get(originHost['port'],originHost['user'],originHost['ip'],originHost['filepath'],"/tmp"))

	for i in hostList:
		if i['Name'] == 'OriginHost':
			continue
		else:
			os.system(scp_put(i['port'],i['user'],i['ip'],i['storepath'],"/tmp/" + fileName))
	
if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Get configuration Files')
	parser.add_argument('-f',type=str,help='configuration file,default to ./config.ini')
	args = parser.parse_args()

	if args.f is not None:
		main(args.f)
	else:
		main()
