#!/bin/sh

chmod +x /var/mail

chown -R vmail:mail /usr/lib/dovecot

test -d  /var/mail/vhosts ||  mkdir -p /var/mail/vhosts
chown -R xmail:mail /var/mail/vhosts
chmod 770 /var/mail/vhosts
touch -c /var/log/dovecot
chmod 777 /var/log/dovecot

chown opendkim /var/run/opendkim


rm -f /run/dovecot/master.pid
rm -f /run/postfix/master.pid

# Substitute configuration
for VARIABLE in `env | cut -f1 -d=`; do
  VV=$(eval echo \$$VARIABLE)
  sed -i "s={{ $VARIABLE }}=$VV=g" /etc/postfix/*.cf
  sed -i "s={{ $VARIABLE }}=$VV=g" /etc/dovecot/*.conf
  sed -i "s={{ $VARIABLE }}=$VV=g" /etc/dovecot/*.conf.ext
  sed -i "s={{ $VARIABLE }}=$VV=g" /etc/opendkim/*
done

if [ ! -f "/etc/ssl/dovecot/server.pem" ]; then
    openssl req -newkey rsa:2048 -x509  -newhdr -nodes -days 3650 -out /etc/ssl/dovecot/server.pem -keyout /etc/ssl/dovecot/server.key  -subj "/C=CN/ST=GD/L=SZ/O=dev/CN=imap.$DOMAIN/emailAddress=$POSTMASTER@$DOMAIN"
fi

if [ ! -f "/etc/opendkim/keys/$DOMAIN/mail.private" ];then
    test -d  /etc/opendkim/keys/$DOMAIN ||  mkdir -p /etc/opendkim/keys/$DOMAIN
    opendkim-genkey -D /etc/opendkim/keys/$DOMAIN/ -d $DOMAIN -s mail
    chmod -R 777 /etc/opendkim/keys/$DOMAIN/
fi

if [ ! -f "/etc/postfix/aliases.db" ];then
    postalias /etc/postfix/aliases
fi

chmod 640 /etc/postfix/dynamicmaps.cf /etc/postfix/dynamicmaps.cf.d/mysql

test -d  /var/mail/postfix ||  mkdir -p /var/mail/postfix
#chmod 777 /var/mail/postfix

exec postfix start & rsyslogd  & opendkim

sleep 3s

exec /usr/sbin/dovecot -c /etc/dovecot/dovecot.conf -F
