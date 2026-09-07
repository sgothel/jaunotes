#! /bin/sh

systemctl stop fail2ban
systemctl status fail2ban
#ps ax | grep fail2ban
rm -v /var/lib/fail2ban/fail2ban.sqlite3 
systemctl start fail2ban
systemctl status fail2ban
