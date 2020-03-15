#!/bin/sh

if [ "${MYSQL_ENV_MYSQL_PASS}" == "**Random**" ]; then
        unset MYSQL_ENV_MYSQL_PASS
fi

MYSQL_HOST=${MYSQL_PORT_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_HOST=${MYSQL_PORT_1_3306_TCP_ADDR:-${MYSQL_HOST}}
MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_PORT=${MYSQL_PORT_1_3306_TCP_PORT:-${MYSQL_PORT}}
MYSQL_USER=${MYSQL_USER:-${MYSQL_ENV_MYSQL_USER}}
MYSQL_PASS=${MYSQL_PASS:-${MYSQL_ENV_MYSQL_PASS}}

[ -z "${MYSQL_HOST}" ] && { echo "=> MYSQL_HOST cannot be empty" && exit 1; }
[ -z "${MYSQL_PORT}" ] && { echo "=> MYSQL_PORT cannot be empty" && exit 1; }
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
#[ -z "${MYSQL_PASS}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

if [ -z "${MYSQL_PASS}" ]; then
	CMD_MYSQL_PASS=""
else
	CMD_MYSQL_PASS="-p${MYSQL_PASS}"
fi

if [ "${MYSQL_DB}" == "--nomal-databases" ]; then
	BACKUP_CMD="mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${CMD_MYSQL_PASS} -e \"show databases\"|grep -Ev \"Database|information_schema|mysql|test|performance_schema\" |xargs mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${CMD_MYSQL_PASS} ${EXTRA_OPTS} --databases | gzip > /backup/"'${BACKUP_NAME}'
else
	BACKUP_CMD="mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${CMD_MYSQL_PASS} ${EXTRA_OPTS} ${MYSQL_DB} | gzip > /backup/"'${BACKUP_NAME}'
fi

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/sh
MAX_BACKUPS=${MAX_BACKUPS}
BACKUP_NAME=${MYSQL_DB}-\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql.gz
echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backup/\${BACKUP_NAME}
fi
if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup -N1 | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup -N1 | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh

RESTORE_CMD="-h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} ${CMD_MYSQL_PASS} "

cat <<EOF >> /restore.sh
#!/bin/sh
if [[ "${MYSQL_DB}" == "--nomal-databases" || "${MYSQL_DB}" == "--all-databases" ]]; then
	  if [ -z "$2" ]; then
	  	DB=""
	  else
	  	DB=$2
	  fi	  
else
		DB="${MYSQL_DB}"
fi
echo "=> Restore database \${DB} from \$1 "
if  gunzip < \$1 | mysql ${RESTORE_CMD} \${DB};then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /backup/mysql_backup.log
tail -F /backup/mysql_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore lates backup"
    until nc -z $MYSQL_HOST $MYSQL_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backup/* | tail -1 | xargs /restore.sh
fi

echo "${CRON_TIME} sh /backup.sh >> /backup/mysql_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec crond -f
