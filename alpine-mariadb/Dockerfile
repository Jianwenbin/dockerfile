FROM alpine:latest
MAINTAINER wb_jian <wb_jian@qq.com> 

RUN apk add --update tzdata mysql mysql-client && rm -f /var/cache/apk/*

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN /bin/echo "Asia/Shanghai" > /etc/timezone

RUN apk del tzdata

ENV LANG zh_CN.UTF-8
ENV REPLICATION_USER repl
ENV REPLICATION_PASS repl

COPY run.sh /run.sh
COPY readiness.sh /readiness.sh
RUN chmod +x /*.sh
COPY my.cnf /opt/my.cnf
WORKDIR /app
VOLUME /app

EXPOSE 3306

ENTRYPOINT ["sh", "/run.sh"] 