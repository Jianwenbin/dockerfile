# mariadb 数据库 镜像

* port  3306   

# ENV 环境变量配置 

* MYSQL_ROOT_PASSWORD  root 用户密码  默认 123456  只能本机访问 
* MYSQL_ADMIN_PASSWORD	admin 用户密码	为空时随机 

* MASTER  是否开启主从复制  true  开启，否则不开启
* REPLICATION_USER	开启主从复制时有效  主从复制账户  默认 repl
* REPLICATION_PASS	开启主从复制时有效  主从复制密码  默认 repl

* SLAVE  是否开启主从复制  true  开启，否则不开启
* MASTER_USER	 主库用户
* MASTER_HOST 主库 Host
* MASTER_PORT 主库 Port
* MASTER_PASSWORD 主库密码
* MASTER_LOG_FILE 同步日志文件 为空时自动获取当前位置
* MASTER_LOG_POS  同步日志位置 为空时自动获取当前位置

# VOLUME 目录
* /app 	数据存储目录
 
