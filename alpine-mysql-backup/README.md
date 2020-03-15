# mysql backup 镜像

mysql backup 工具

port  8080


#ENV 环境变量配置 

CRON_TIME   0 0 * * *  定时任务
MYSQL_DB			myDB   备份数据库  --nomal-databases 备份除去系统数据库外的所有数据库    --all-databases  所有数据库
MYSQL_HOST	数据库地址
MYSQL_PORT	数据库端口
MYSQL_USER	数据库用户
MYSQL_PASS	数据库密码
INIT_BACKUP	true  false   启动后立即开始备份
INIT_RESTORE_LATEST true false  启动后立即开始还原最后一次的备份

# VOLUME 目录
/backup   备份文件所在目录