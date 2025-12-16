#! /bin/sh

tail -f /var/log/mail.{log,error,info} /var/log/dovecot.log /var/log/spamassassin/spamd.log
