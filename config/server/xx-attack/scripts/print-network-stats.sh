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

echo "ipv4  acl_external_input"
echo " pkts bytes target     prot opt in     out     source               destination"
iptables -L acl_external_input -n -v | grep -E "ctstate|#conn|ssh|http|limit|DROP"
echo
echo "ipv6  acl_external_input"
ip6tables -L acl_external_input -n -v | grep -E "ctstate|#conn|ssh|http|limit|DROP"
echo

echo "ipv4  syn-flood"
iptables -L acl_syn_flood -n -v | tail -n 2
echo
echo "ipv6  syn-flood"
ip6tables -L acl_syn_flood -n -v | tail -n 2
echo

