#*cofing=utf-8

import os
import subprocess

def getDestList(filepath:str)->list:
    with open(filepath,'r') as f:
        lines = f.readlines()

    return lines

def sendFiles(srcFile:str,destHost:str,destPath:str)->int:
    ip_port = destHost.split(':')
    if len(ip_port) != 2:
        print("ERROR:{dest} has wrong format")
        return -1

    os.popen("scp -o ConnectTimeout=1 -P {port} {srcfile} {desthost}:{destpath}".format(srcfile=srcFile,desthost=ip_port[0].strip('\n'),destpath=destPath,port=ip_port[1].strip('\n')))
    return 0

def sendFilesLoop(srcfile:str,destList:list,destPath:str)->int:
    for i in destList:
        sendFiles(srcfile,i,destPath)

    print("Hello")

def main():
    sendFilesLoop("./host.txt",getDestList("./host.txt"),"/tmp")


if __name__ == "__main__":
    main()
