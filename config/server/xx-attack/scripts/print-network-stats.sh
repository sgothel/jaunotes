#!/bin/sh

# install: ss, top, ..

top -bn1 | head | grep Cpu | awk ' { printf "CPU %3d%, ", 100-$8 }' ; uptime | sed 's/^.*load average: /load average: /g'
free -h
echo

printf "total conn %6d, syn  %6d \t\tlisten-drops %9d\t\t\t\t(Netstat Current)\n" \
    $(ss -tan state established | wc -l) \
    $(ss -tan state syn-recv | wc -l) \
    $(netstat -s | grep "SYNs" | awk '{ print $1 }')

printf "time-wait  %6d \t\t\tclose-wait %6d \t\tssh %2d, syn %d\n" \
    $(ss -tan state time-wait | wc -l) \
    $(ss -tan state close-wait | wc -l) \
    $(ss -tan state established | grep :22 | wc -l) \
    $(ss -tan state syn-recv | grep :22 | wc -l)

printf "https conn %6d, syn  %6d \t\thttp conn  %6d, syn  %d \tgit %2d, syn %d\n" \
    $(ss -tan state established | grep :443 | wc -l) \
    $(ss -tan state syn-recv | grep :443 | wc -l) \
    $(ss -tan state established | grep :80 | wc -l) \
    $(ss -tan state syn-recv | grep :80 | wc -l) \
    $(ss -tan state established | grep :9418 | wc -l) \
    $(ss -tan state syn-recv | grep :9418 | wc -l)

printf "cgit #     %6d \t\t\thttpd #    %6d\t\t\t\t(Process Count)\n" \
    $(ps ax | grep cgit.cgi | wc -l) \
    $(ps ax | grep apache2 | wc -l)

echo

printf "https ipv4 %6d, ipv6 %6d \t\thttp ipv4  %6d, ipv6 %d\t\t\t(IP Buckets: %6d total)\n" \
    $(cat /proc/net/ipt_hashlimit/https-limit | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/https-limit | wc -l) \
    $(cat /proc/net/ipt_hashlimit/http-limit | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/http-limit | wc -l) \
    $((  $(cat /proc/net/ipt_hashlimit/https-limit | wc -l) \
       + $(cat /proc/net/ip6t_hashlimit/https-limit | wc -l) \
       + $(cat /proc/net/ipt_hashlimit/http-limit | wc -l) \
       + $(cat /proc/net/ip6t_hashlimit/http-limit | wc -l) ))

printf "syn   ipv4 %6d 1/s, %4d 3/s, %d > 6/s, ipv6  %6d 1/s, %d 3/s, %d > 6/s\t\t(IP Buckets: %6d total)\n" \
    $(cat /proc/net/ipt_hashlimit/synflood1 | wc -l) \
    $(cat /proc/net/ipt_hashlimit/synflood3 | wc -l) \
    $(cat /proc/net/ipt_hashlimit/synflood | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/synflood1 | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/synflood3 | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/synflood | wc -l) \
    $((  $(cat /proc/net/ipt_hashlimit/synflood1 | wc -l) \
       + $(cat /proc/net/ipt_hashlimit/synflood3 | wc -l) \
       + $(cat /proc/net/ipt_hashlimit/synflood | wc -l) \
       + $(cat /proc/net/ip6t_hashlimit/synflood1 | wc -l) \
       + $(cat /proc/net/ip6t_hashlimit/synflood3 | wc -l) \
       + $(cat /proc/net/ip6t_hashlimit/synflood | wc -l) ))

#printf "ssh   ipv4 %6d, ipv6 %6d\n" \
#    $(cat /proc/net/ipt_hashlimit/ssh-limit | wc -l) \
#    $(cat /proc/net/ip6t_hashlimit/ssh-limit | wc -l)

echo

# nft set addr-set-apache-badbots of table f2b-table may contain (a) million(s) of entries,
# listing them will choke this script!
#
#printf "dos-syn    %6d, ssh %4d, http[bots %7d] \t\t\t\t\t(Banned:     %7d total, dropped %7d)\n" \
#    $(fail2ban-client get dos-syn banned | wc -w) \
#    $(fail2ban-client get sshd banned | wc -w) \
#    $(fail2ban-client get apache-badbots banned | wc -w) \
#    $(fail2ban-client banned | grep -E -o -e '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' -e '([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}' | wc -l) \
#    $(nft list chain inet f2b-table f2b-chain 2>/dev/null | grep packets | awk ' { sum += $9 } END { print sum }')
#
# Instead, query the fail2ban database for the row-count of banned entries (IPs)
#
printf "fail2ban banned %7d IPs and dropped %7d packets (nftable)\n" \
    $(echo "SELECT count (*) from bans;" | sqlite3 -readonly /var/lib/fail2ban/fail2ban.sqlite3) \
    $(nft list chain inet f2b-table f2b-chain 2>/dev/null | grep packets | awk ' { sum += $9 } END { print sum }')
echo

echo "ipv4  dos_limiter"
iptables -L dos_limiter -n -v --line-numbers | grep -v -E "^2 |^3 |^4 |^5 |^6 |^7 |^8 |^10 " | tail -n +2
echo
echo "ipv6  dos_limiter"
ip6tables -L dos_limiter -n -v --line-numbers | grep -v -E "^2 |^3 |^4 |^5 |^6 |^7 |^8 |^9 |^10 |^11 |^13 " | tail -n +3
echo

echo "ipv4  syn-flood"
iptables -L syn_flood -n -v --line-numbers | tail -n +3
echo
echo "ipv6  syn-flood"
ip6tables -L syn_flood -n -v --line-numbers | tail -n +3
echo

