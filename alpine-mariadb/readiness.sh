#!/bin/sh

if [[ "${SLAVE}" == "true" ]]; then
	 if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
     MYSQL_ROOT_PASSWORD=123456
	 fi
   
	 array=$(mysql -uroot -p${MYSQL_ROOT_PASSWORD}  -e "show slave status\G"|grep "Running" |awk '{print $2}')
	 Slave_IO_Running=`echo ${array} | awk -F " " '{print $1}'`
	 Slave_SQL_Running=`echo ${array} | awk -F " " '{print $2}'`

 	 if [ "${Slave_IO_Running}" == "Yes" ] || [ "${Slave_IO_Running}" == "Yes" ]; then 
 	 	 echo "Slave_IO_Running:${Slave_IO_Running},Slave_IO_Running:${Slave_IO_Running}"
 	 	 exit 0;
 	 else 
 	 	 exit 1;
 	 fi

else
	 stillRunning=$(ps -ef |grep "/usr/bin/mysqld" |grep -v "grep")
	 if [ "$stillRunning" ] ; then 
	 	 exit 0;
	 fi
	 exit 1;    
fi
