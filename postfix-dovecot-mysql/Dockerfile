FROM alpine:latest

MAINTAINER wurui <609028727@qq.com>
  
RUN apk add --update postfix postfix-mysql dovecot dovecot-mysql policyd-spf-fs rsyslog opendkim opendkim-utils #spamassassin  

RUN rm -f /var/cache/apk/*

# MYSQL_HOST
# MYSQL_PORT
# MYSQL_USER
# MYSQL_PASSWORD
# MYSQL_DB
ENV POSTMASTER="postmaster"  \
	DOMAIN="example.com"	\
	MYSQL_PORT="3306"

RUN mkdir -p /var/mail/vhosts && mkdir -p /var/run/opendkim
RUN rm -rf /etc/dovecot  && rm -rf /etc/ssl/dovecot/* && rm -rf /var/spool/postfix

COPY entrypoint.sh /entrypoint.sh
COPY postfix /etc/postfix
COPY dovecot /etc/dovecot
COPY opendkim /etc/opendkim
#COPY spamassassin/local.cf /etc/spamassassin/
#COPY spamassassin/spamassassin /etc/default/

RUN chmod +x /*.sh
RUN adduser -G mail -D -u 5000 -h /var/mail/vhosts -s /sbin/nologin xmail

#SMTP #SMTP SSL #IMAPS  #POP3 #POP3S
EXPOSE 25  465      993      995 

ENTRYPOINT ["sh", "/entrypoint.sh"] 

#CMD ["sh","entrypoint.sh"]