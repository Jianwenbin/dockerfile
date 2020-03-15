FROM alpine:latest

MAINTAINER wurui <609028727@qq.com>

RUN apk --update add apk-cron &&\
    apk add mysql-client &&\
    apk add tzdata &&\    
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime  &&\
    /bin/echo "Asia/Shanghai" > /etc/timezone &&\
    apk del tzdata &&\
    rm -rf /tmp/* /var/cache/apk/* 
    
ENV CRON_TIME="0 0 * * *" \
		MYSQL_DB="--nomal-databases" \
		LANG="zh_CN.UTF-8"
		
ADD run.sh /run.sh
RUN chmod +x /*.sh

VOLUME ["/backup"]

CMD ["/run.sh"]
