#!/bin/bash
#安装软件源
echo "正在安装软件源"
rpm -ivh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
#安装zabbix-server
echo "正在安装zabbix-server"
yum install -y zabbix-server-mysql
#安装前端网页
echo "正在安装zabbix-web"
yum install -y zabbix-web-mysql
#安装数据库
echo "正在安装mariadb数据库"
yum install -y mariadb-server
#配置数据库，设置数据存放位置为/usr/local/zabbix/mysql
echo "正在初始化数据库，数据库文件保存在/usr/local/zabbix/mysql目录下"
mkdir -p /usr/local/zabbix/mysql
chown -R mysql /usr/local/zabbix/mysql
sed -i "s/datadir=\/var\/lib\/mysql/datadir=\/usr\/local\/zabbix\/mysql/g" /etc/my.cnf
#启动数据库
echo "启动数据库"
systemctl enable mariadb
systemctl start mariadb
echo "请手动设置数据库"
echo "use mysql;"
echo "update user set password=password('password-for-root') where user='root';"
echo "grant all privileges on *.* to 'root'@'%' identified by 'password-for-root' with grant option;"
echo "create database zabbix character set utf8 collate utf8_bin;"
echo "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix-password';"
echo "flush privileges;"
read -p "press any key to continue"
echo "开始导入zabbix数据库文件"
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
#修改zabbix-server配置文件
echo "修改zabbix-server配置文件,以root身份运行zabbix-server"
sed -i "s/# DBPassword=/DBPassword=zabbix/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# AllowRoot=0/AllowRoot=1/g" /etc/zabbix/zabbix_server.conf
#启动zabbix-server
echo "启动zabbix-server"
systemctl enable zabbix-server
systemctl start zabbix-server
#修改php时区
echo "修改php时区"
sed -i "s/# php_value date.timezone Europe\/Riga/php_value date.timezone Asia\/Shanghai/g" /etc/httpd/conf.d/zabbix.conf
#设置字体
echo "正在设置字体"
wget https://s3.cn-north-1.amazonaws.com.cn/hualai-big-data/simsun.ttc
mkdir -p /usr/local/zabbix/font
mv simsun.ttc /usr/local/zabbix/font
rm -rf /etc/alternatives/zabbix-web-font
ln -s /usr/local/zabbix/font/simsun.ttc /etc/alternatives/zabbix-web-font
#重启httpd
echo "重启httpd"
systemctl enable httpd
systemctl restart httpd
#安装agent
echo "安装zabbix-agent"
yum install -y zabbix-agent
systemctl enable zabbix-agent
systemctl start zabbix-agent
#访问前端配置
echo "打开浏览器，访问网址进入下一步配置：http://本地ip地址/zabbix"
