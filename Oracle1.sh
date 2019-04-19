#!/bin/bash
#uthor : shan dong jia you
# create date : 2018-05-22
# oracle version : 11gr2
# linux version : redhat 7.4
# ram : 2G
############################################################
isroot()
{
 if [[ ${user} -lt root ]];then
        echo -e"\n\e[1;31mthis script must be executed as root. \e[0m"
        exit 1
 else
        echo -e "\n\e[1;36muser is root ! \e[0m"
 fi
}
mount_iso()
{
 if [ -f /usr/local/src/rhel-server-7.4-x86_64-dvd.iso ];then
        echo -e "\n\e[1;36m rhel-server-7.4-x86_64-dvd.iso file is exsit! \e[0m"
        mkdir -p /media/iso && mount -t iso9660 -o loop /usr/local/src/rhel-server-7.4-x86_64-dvd.iso /media/iso >> /dev/null
        if [ $? -eq 0 ];then
                echo -e "\n\e[1;36m mounted is secussful! \e[0m"
        fi
 else
        echo -e "\n\e[1;31m rhel-server-7.4-x86_64-dvd.iso file is not exsit!"
        exit 3
 fi

}
yum_repo()
{
rm -rf /etc/yum.repos.d/* && cat << EOF >>/etc/yum.repos.d/iso.repo
[ISO]
name=myrepo
baseurl=file:///media/iso
enabled=1
gpgcheck=0
gpgkey=file:///media/iso/RPM-GPG-KEY-redhat-release
EOF
if [ $? -eq 0 ];then
        echo -e "\n\e[1;36mcreate iso.repo secussful! \e[0m"
else
        echo -e "\n\e[1;31mcreate iso.repo fail! \e[0m"
fi
}
packagecheck()
{
for package in binutils compat-libcap1 compat-libstdc++-33 compat-libstdc++-33*.i686 elfutils-libelf-devel gcc gcc-c++ glibc*.i686 glibc glibc-devel glibc-devel*.i686 ksh libgcc*.i686 libgcc libstdc++ libstdc++*.i686 libstdc++-devel libstdc++-devel*.i686 libaio libaio*.i686 libaio-devel libaio-devel*.i686 make sysstat unixODBC unixODBC*.i686 unixODBC-devel unixODBC-devel*.i686 libXp
do
        rpm -qa $package 2 > /dev/null
        if [[ $? -eq 0 ]];then
                yum -y install $package
                echo -e "\n\e[1;36m $package already installed! \e[0m"
        else
                echo -e "\n\e[1;31m install is error! \e[0m"
        fi
done
cd /usr/local/src
rpm -ivh --force --nodeps compat-libstdc++-33-3.2.3-61.i386.rpm
rpm -ivh --force --nodeps compat-libstdc++-33-3.2.3-69.el6.x86_64.rpm
rpm -ivh --force --nodeps libaio-devel-0.3.105-2.i386.rpm
rpm -ivh --force --nodeps libgcc-3.4.6-3.i386.rpm
rpm -ivh --force --nodeps libstdc++-3.4.6-3.1.i386.rpm
rpm -ivh --force --nodeps unixODBC-2.2.11-7.1.i386.rpm
rpm -ivh --force --nodeps unixODBC-devel-2.2.11-7.1.i386.rpm
yum -y install bc >> /dev/null
}
#修改主机名
hostname()
{
hostnamectl set-hostname oracledb
}
#主机名与IP解析
hosts()
{
echo $1 oracledb >> /etc/hosts
}
#设置selinux宽松模式
setenforce 0
#不要用useradd命名函数
iuseradd()
{
if [[ `cat /etc/group | grep "oinstall" | awk -F : '{print $1}'` = "" ]];then
        groupadd oinstall
        echo -e "\n\e[1;36m create group oinstall succsess! \e[0m"

else
        echo -e "\n\e[1;31mgroup oinstall is already! \e[0m"
fi
if [[ `cat /etc/group | grep "dba" | awk -F : '{print $1}'` = "" ]];then
        groupadd dba
        echo -e "\n\e[1;36m create group dba succsess! \e[0m"
		else
        echo -e "\n\e[1;31mgroup dba is already! \e[0m"
fi
if [[ `cat /etc/passwd | grep "oracle" | awk -F : '{print $1}'` = "" ]];then
        useradd -g oinstall -G dba oracle
        echo -e "\n\e[1;36m create user oracle is success! \e[0m"

else
        echo -e "\a\n\e[1;31moracle用户已存在！\e[0m"
fi
if [ $? -eq 0 ];then
        echo $1 | passwd oracle --stdin
else
        echo -e "\n\e[1;31m create is fail \e[0m"
fi
}
sysctl_1()
{
cat >> /etc/sysctl.conf << EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = $1
kernel.shmmax = $2
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048575
EOF
sysctl -p
}
ilimits()
{
cat >> /etc/security/limits.conf << EOF
oracle      soft    nproc   2047
oracle      hard    nproc   16384
oracle      soft    nofile  1024
oracle      hard    nofile  65536
oracle      soft    stack   10240
EOF
}
ologin()
{
abc=`find / -name pam_limits.so`
cat >> /etc/pam.d/login << EOF
session    required     ${abc}
EOF
}
iprofile()
{
path=`cat /home/oracle/.bash_profile | grep PATH | awk -F = '{print $2}'`
cat >> /home/oracle/.bash_profile << EOF
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11g/db_1
export ORACLE_SID=orcl
export PATH=\$PATH:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/usr/lib
EOF
source  /home/oracle/.bash_profile
}
idir()
{
mkdir -p /u01/app/oracle/product/11g/db_1
chmod 755 -R /u01/app/oracle/product/11g/db_1
chown -R oracle:oinstall /u01/app/oracle
}
yum_unzip()
{
yum -y install unzip
}
unzip_oracle()
{
cd /usr/local/src
unzip linux.x64_11gR2_database_1of2.zip
unzip linux.x64_11gR2_database_2of2.zip
}
isroot
#mount_iso
#yum_repo
packagecheck
hostname
echo -e "\a\n\e[1;36m请输入你的ip: \e[0m"
stty erase ^H
read ip
hosts ${ip} 
echo -e "\n\e[1;36m请输入oracle的密码： \e[0m"
stty erase ^H
read oracle_passwd
iuseradd ${oracle_passwd}
echo -e "\a\n\e[1;31m请输入你的系统内存（以G为标准，只输入数字）： \e[0m"
stty erase ^H
read iram
ishmall=`echo "scale=1;${iram} * 1024 * 1024 / 4 * 0.6" | bc`
ishmmax=`echo "scale=1;${iram} * 1024 * 1024 * 1024 * 0.6" | bc`
sysctl_1 ${ishmall%.*} ${ishmmax%.*}
ilimits
ologin
iprofile 
idir 
yum_unzip
unzip_oracle
#只安装软件
sed -i 's/oracle.install.option=/&INSTALL_DB_SWONLY/' /usr/local/src/database/response/db_install.rsp
sed -i 's/ORACLE_HOSTNAME=/&oracledb/' /usr/local/src/database/response/db_install.rsp
sed -i 's/UNIX_GROUP_NAME=/&oinstall/' /usr/local/src/database/response/db_install.rsp
#oracle清单路径
#所赋值为路径，分隔符用%
sed -i 's%INVENTORY_LOCATION=%&/u01/app/oracle/oraInventory%' /usr/local/src/database/response/db_install.rsp
#修改oracle语言
sed -i 's/SELECTED_LANGUAGES=/&en,zh_CN/' /usr/local/src/database/response/db_install.rsp
#修改ORACLE_BASE,ORACLE_HOME
sed -i 's%ORACLE_HOME=%&/u01/app/oracle/product/11g/db_1%' /usr/local/src/database/response/db_install.rsp
sed -i 's%ORACLE_BASE=%&/u01/app/oracle%' /usr/local/src/database/response/db_install.rsp
#修改oracle版本为EE企业版
sed -i 's/oracle.install.db.InstallEdition=/&EE/' /usr/local/src/database/response/db_install.rsp
#修改数据库的管理组
sed -i 's/oracle.install.db.DBA_GROUP=/&dba/' /usr/local/src/database/response/db_install.rsp
#oracle安装管理组
sed -i 's/oracle.install.db.OPER_GROUP=/&oinstall/' /usr/local/src/database/response/db_install.rsp
#设计数据库用途为一般用途
sed -i 's/oracle.install.db.config.starterdb.type=/&GENERAL_PURPOSE/' /usr/local/src/database/response/db_install.rsp
#设计全局数据库的名字为orcl
sed -i 's/oracle.install.db.config.starterdb.globalDBName=/&orcl/' /usr/local/src/database/response/db_install.rsp
#设计数据库SID
sed -i 's/oracle.install.db.config.starterdb.SID=/&orcl/' /usr/local/src/database/response/db_install.rsp
#设计数据库的编码格式
sed -i "s/oracle.install.db.config.starterdb.characterSet=AL32UTF8/oracle.install.db.config.starterdb.characterSet=ZHS16GBK/" /usr/local/src/database/response/db_install.rsp

#更改oracle所有用户密码join
sed -i 's/oracle.install.db.config.starterdb.password.ALL=/&join/' /usr/local/src/database/response/db_install.rsp
sed -i 's/DECLINE_SECURITY_UPDATES=/&true/' /usr/local/src/database/response/db_install.rsp
#启动响应文件
su - oracle -c 'cd /usr/local/src/database;./runInstaller -silent -force -responseFile /usr/local/src/database/response/db_install.rsp' 

