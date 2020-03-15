# postfix-dovecot+mysql+opendkim+spf+spamassassin 邮箱服务器镜像

* smtp  25 （不支持）  
* smtps  465 
* imap  143  （不支持）
* imaps	993
* pop3  110 （不支持）
* pop3s  995


# ENV 环境变量配置 

* DOMAIN 域名地址 默认 example.com
* POSTMASTER postmaster账户 默认 postmaster

* MYSQL_HOST  mysql 地址 
* MYSQL_PORT  mysql端口 默认 3306
* MYSQL_USER  mysql 登录名
* MYSQL_PASSWORD  mysql 密码
* MYSQL_DB    数据库

# VOLUME 目录
* /var/mail 	邮件存储目录
 
