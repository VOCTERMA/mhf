#!/bin/bash
ventory=`cat /usr/local/src/database/response/db_install.rsp | grep 'INVENTORY_LOCATION=' | awk -F = '{print $2}'`
${ventory}/orainstRoot.sh
ioracle_home=`cat /home/oracle/.bash_profile | grep 'export ORACLE_HOME' | awk -F = '{print $2}'` 
${ioracle_home}/root.sh 
su - oracle -c 'netca /silent /responseFile /usr/local/src/database/response/netca.rsp'
if [ $? -lt 0 ];then
        echo -e '\a\n\e[1;31m执行错误！\e[0m'
        exit 1
fi

idbca.rep()
{
sed -i "s/GDBNAME = \"orcl11g.us.oracle.com\"/GDBNAME = \"orcl\"/" /usr/local/src/database/response/dbca.rsp
sed -i "s/SID = \"orcl11g\"/SID = \"orcl\"/" /usr/local/src/database/response/dbca.rsp
sed -i "s/#SYSPASSWORD = \"password\"/SYSPASSWORD = \"$1\"/" /usr/local/src/database/response/dbca.rsp
sed -i "s/#SYSTEMPASSWORD = \"password\"/SYSTEMPASSWORD = \"$1\"/" /usr/local/src/database/response/dbca.rsp
sed -i 's%\#DATAFILEDESTINATION =%DATAFILEDESTINATION = /u01/app/oracle/oradata%' /usr/local/src/database/response/dbca.rsp
sed -i 's/#CHARACTERSET = \"US7ASCII\"/CHARACTERSET = \"ZHS16GBK\"/' /usr/local/src/database/response/dbca.rsp
sed -i "s/#TOTALMEMORY = \"800\"/TOTALMEMORY = \"$2\"/" /usr/local/src/database/response/dbca.rsp
}
echo -e "\a\n\e[1;36m请输入你的数据库用户密码：\e[0m"
stty erase ^H
read password
echo -e "\a\n\e[1;36m请输入你的系统内存（以M为标准，只输入纯数字）：\e[0m"
stty erase ^H
read num
num_1=`echo "scale=1;${num} * 0.6" | bc`
idbca.rep ${password} ${num_1%.*}
su - oracle -c 'dbca -silent -responseFile /usr/local/src/database/response/dbca.rsp'
cat >> /etc/rc.d/rc.local << EOF
su - oracle -c 'lsnrctl start'
su - oracle -c 'dbstart'
EOF
chmod +x /etc/rc.d/rc.local
sed -i 's%orcl\:/u01/app/oracle/product/11g/db_1\:N%orcl\:/u01/app/oracle/product/11g/db_1\:Y%' /etc/oratab
#$1 $ORACLE_HOME 作为非变量需要转义符
sed -i "s%ORACLE_HOME_LISTNER=\$1%ORACLE_HOME_LISTNER=\${ORACLE_HOME}%" /u01/app/oracle/product/11g/db_1/bin/dbstart


