#!/bin/sh

# watch 'netstat -tuna | wc -l'
# watch 'netstat -tuna | grep :443 | wc -l; netstat -tuna | grep SYN | wc -l'
# ss -s
# ss -tan state syn-recv
# ss -tan state syn-recv | less
# ss -tan state syn-recv | wc
# ss -tan state established | wc
# ss -uan
# nstat -az | grep -Ei 'Listen|Syncookie|TCP'
# nstat -az | grep -Ei "Listen|Syncookie|TCP"
# nstat -az | grep -e "Listen|Syncookie|TCP"
# nstat -az | grep -ei "Listen|Syncookie|TCP"

free -h
echo

echo "Stats"
echo -n "443 ns " ; netstat -tuna | grep :443 | wc -l | tr -d '\n\r' ; printf "\t ss " ; ss -tan state established | wc -l
echo -n "syn ns " ; netstat -tuna | grep SYN  | wc -l | tr -d '\n\r' ; printf "\t ss " ; ss -tan state syn-recv    | wc -l
echo -n "cgit # " ; ps ax | grep cgit.cgi     | wc -l | tr -d '\n\r' ; printf "\t httpd " ; ps ax | grep apache2 | wc -l
echo

echo "Tracking Limited IPs"
echo -n "ssh   ipv4 " ; cat /proc/net/ipt_hashlimit/ssh-limit   | wc -l | tr -d '\n\r' ; printf "\t ipv6 " ; cat /proc/net/ip6t_hashlimit/ssh-limit   | wc -l
echo -n "http  ipv4 " ; cat /proc/net/ipt_hashlimit/http-limit  | wc -l | tr -d '\n\r' ; printf "\t ipv6 " ; cat /proc/net/ip6t_hashlimit/http-limit  | wc -l
echo -n "https ipv4 " ; cat /proc/net/ipt_hashlimit/https-limit | wc -l | tr -d '\n\r' ; printf "\t ipv6 " ; cat /proc/net/ip6t_hashlimit/https-limit | wc -l
echo

echo "ipv4  acl_dos_limiter"
echo " pkts bytes target     prot opt in     out     source               destination"
iptables -L acl_dos_limiter -n -v | grep -v -E "icmptype (0$|3$|3 code 4$|11$|12$|13$)|acl_syn_flood"
echo
echo "ipv6  acl_dos_limiter"
ip6tables -L acl_dos_limiter -n -v | grep -v -E "ipv6-icmptype (1$|2$|3$|4$|129$|133$|134$|135$|136$|)|acl_syn_flood"
echo

echo "ipv4  syn-flood"
iptables -L acl_syn_flood -n -v | tail -n 2
echo
echo "ipv6  syn-flood"
ip6tables -L acl_syn_flood -n -v | tail -n 2
echo

