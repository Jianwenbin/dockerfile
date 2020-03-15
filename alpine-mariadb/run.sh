#!/bin/sh

if [ ! -d "/app/cnf" ]; then
	mkdir /app/cnf && mkdir /app/cnf/conf.d && cp /opt/my.cnf /app/cnf/my.cnf
fi

StartMySQL(){
if [ -d /app/data/mysql ]; then
  echo "[i] MySQL directory already present, skipping creation"
  mysqld_safe --defaults-file=/app/cnf/my.cnf --datadir=/app/data --user=root  &
else
  echo "[i] MySQL data directory not found, creating initial DBs"

  mysql_install_db --user=root --datadir=/app/data/> /dev/null

  if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
    MYSQL_ROOT_PASSWORD=123456
  fi

  if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
  fi

	mysqld_safe --defaults-file=/app/cnf/my.cnf --datadir=/app/data --user=root &

  for i in $(seq 1 30); do
	  sleep 1
	  if mysql -u root -e "status" > /dev/null ; then break; fi
  done

	tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
      return 1
  fi
  if [[ "$MYSQL_ADMIN_PASSWORD" == "" ]]; then
    MYSQL_ADMIN_PASSWORD=$(date +%s%N | md5sum | head -c 10)
  fi


  cat << EOF > $tfile
delete from user;
FLUSH PRIVILEGES;
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
GRANT GRANT OPTION ON *.* TO 'root'@'127.0.0.1';
CREATE USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
GRANT GRANT OPTION ON *.* TO 'root'@'localhost';
CREATE USER 'root'@'::1' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'::1' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
GRANT GRANT OPTION ON *.* TO 'root'@'::1';
CREATE USER 'admin'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}' ;
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}' WITH GRANT OPTION;
GRANT GRANT OPTION ON *.* TO 'admin'@'%';
FLUSH PRIVILEGES;
EOF
	echo "[i] Create User ...."

  mysql -uroot -D mysql < $tfile
  rm -f $tfile

  echo "[i] MySQL admin Password: $MYSQL_ADMIN_PASSWORD"
fi
}


RestoreFromMarster(){
  if [ -d "/tmp/ready" ];then
    exit 1;
  fi
  touch /tmp/ready;
  if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ] && [ -n "${MYSQL_PORT_3306_TCP_PORT}" ]; then
    MASTER_HOST="${MYSQL_PORT_3306_TCP_ADDR}"
    MASTER_PORT="${MYSQL_PORT_3306_TCP_PORT}"
  fi
  
  if mysql -h ${MASTER_HOST} -P ${MASTER_PORT} -u ${MASTER_USER} -p${MASTER_PASSWORD} -e "SHOW MASTER STATUS;" > /dev/null ; then 
  
		#stop slave
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "STOP SLAVE;"
		  
    BACKUP_NAME=$(date +\%Y.\%m.\%d.\%H\%M\%S).sql			  
    BACKUP_CMD="mysql -h${MASTER_HOST} -P${MASTER_PORT} -u${MASTER_USER} -p${MASTER_PASSWORD} -e \"show databases\"|grep -Ev \"Database|information_schema|mysql|performance_schema\" |xargs mysqldump -h${MASTER_HOST} -P${MASTER_PORT} -u${MASTER_USER} -p${MASTER_PASSWORD} --master-data=2 --single-transaction --triggers --routines -B --databases > /app/${BACKUP_NAME}"
		  
    if eval ${BACKUP_CMD} ;then
        echo "   Backup Master succeeded"
    else
        echo "   Backup Master failed"
        rm -rf /app/${BACKUP_NAME}
        rm -rf /tmp/ready
        exit 1;
    fi
    tmp=`grep -i 'CHANGE MASTER TO MASTER_LOG_FILE=' /app/${BACKUP_NAME}`
		  
    MASTER_LOG_FILE=`echo $tmp | awk -F "[=;']" '{print $3}'`
    MASTER_LOG_POS=`echo $tmp | awk -F "[=;']" '{print $5}'`
		  
    RESTORE_CMD="-uroot -p${MYSQL_ROOT_PASSWORD} "
    if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
        MYSQL_ROOT_PASSWORD=123456
    fi
    if  mysql ${RESTORE_CMD} < /app/${BACKUP_NAME}  ;then
        echo "Restore succeeded"
        rm -rf /app/${BACKUP_NAME}				    
    else
        echo "Restore failed"
        rm -rf /app/${BACKUP_NAME}
        rm -rf /tmp/ready
        exit 1;
    fi
		  
    echo 'MASTER_LOG_FILE: ${MASTER_LOG_FILE} , MASTER_LOG_POS: ${MASTER_LOG_POS}'
		    
    if [ ! -n "${MASTER_LOG_FILE}" ] && [ ! -n "${MASTER_LOG_POS}" ]; then
        echo ' Cannot configure slave, miss env MASTER_LOG_FILE and MASTER_LOG_POS'
        rm -rf /tmp/ready
        exit 1;
    fi

    echo "=> Setting master connection info on slave"
    echo 	"CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}',MASTER_USER='${MASTER_USER}',MASTER_PASSWORD='${MASTER_PASSWORD}',MASTER_PORT=${MASTER_PORT},MASTER_LOG_FILE='${MASTER_LOG_FILE}',MASTER_LOG_POS=${MASTER_LOG_POS},MASTER_CONNECT_RETRY=7;"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}',MASTER_USER='${MASTER_USER}',MASTER_PASSWORD='${MASTER_PASSWORD}',MASTER_PORT=${MASTER_PORT},MASTER_LOG_FILE='${MASTER_LOG_FILE}',MASTER_LOG_POS=${MASTER_LOG_POS},MASTER_CONNECT_RETRY=7;"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "START SLAVE;"
		  
    rm -rf /tmp/ready
  else   
    rm -rf /tmp/ready
    exit 1; 
  fi
  
}


if [[ "${SLAVE}" == "true" ]]; then
	
  echo "=> Configuring MySQL replication as slave ..."
	
  if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ] && [ -n "${MYSQL_PORT_3306_TCP_PORT}" ]; then
    MASTER_HOST="${MYSQL_PORT_3306_TCP_ADDR}"
    MASTER_PORT="${MYSQL_PORT_3306_TCP_PORT}"
  fi

  if [ ! -n "${MASTER_USER}" ] && [ ! -n "${MASTER_PASSWORD}" ]; then
	  echo ' Cannot configure slave, miss env MASTER_USER and MASTER_PASSWORD'
    exit 1;
  fi

  if [ -n "${MASTER_HOST}" ] && [ -n "${MASTER_PORT}" ]; then
    if [ ! -f /app/cnf/conf.d/slave.cnf ]; then
    		    		
    		CONF_FILE="/app/cnf/conf.d/slave.cnf"
        RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
        echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"

        cat << EOF > ${CONF_FILE}
[mysqld]
server-id = ${RAND}
log-bin = mysql-bin
EOF
        StartMySQL;       
        
        RestoreFromMarster;
        
        echo "=> Done!"
    else
        echo "=> MySQL replicaiton slave already configured, skip"
        StartMySQL;
    fi
    rm -rf /tmp/ready
  else
    echo "=> Cannot configure slave, miss env MASTER_HOST and MASTER_PORT"
    exit 1
  fi

elif [[ "${MASTER}" == "true" ]]; then

  echo "=> Configuring MySQL replication as master ..."
  if [ ! -f /app/cnf/conf.d/master.cnf ]; then
      CONF_FILE="/app/cnf/conf.d/master.cnf"
      RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
      echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"

      cat << EOF > ${CONF_FILE}
[mysqld]
server-id = ${RAND}
log-bin = mysql-bin
binlog_format = MIXED
binlog-ignore-db = mysql
binlog-ignore-db = information_schema
binlog-ignore-db = performance_schema
expire_logs_days = 7
EOF

      StartMySQL;

      echo "=> Creating a log user ${REPLICATION_USER}:${REPLICATION_PASS}"
      mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER '${REPLICATION_USER}'@'%' IDENTIFIED BY '${REPLICATION_PASS}'"
			mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT reload,process,replication slave,replication client,super,select,event,trigger,show view,show databases ON *.* TO '${REPLICATION_USER}'@'%'"
			
      echo "=> Done!"
  else
      echo "=> MySQL replication master already configured, skip"
      StartMySQL;
  fi

else
	  StartMySQL;
fi

shutdown()
{
		 mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
}

trap "echo 'shutting down...'; shutdown" SIGKILL SIGQUIT SIGTERM;

wait

echo 'MySQL stopped.'