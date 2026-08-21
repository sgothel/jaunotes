#!/bin/sh

# install: ss, top, ..

top -bn1 | head | grep Cpu | awk ' { printf "CPU %3d%, ", 100-$8 }' ; uptime | sed 's/^.*load average: /load average: /g'
free -h
echo

printf "total conn %6d, syn  %6d \t\tlisten-drops %6d\t\t\t\t(Netstat)\n" \
    $(ss -tan state established | wc -l) \
    $(ss -tan state syn-recv | wc -l) \
    $(netstat -s | grep "SYNs" | awk '{ print $1 }')

printf "https conn %6d, syn  %6d \t\tsyn-flood  %6d 2/s, %d 6/s, %d above\t\t(syn-flood IPs)\n" \
    $(ss -tan state established | grep :443 | wc -l) \
    $(ss -tan state syn-recv | grep :443 | wc -l) \
    $(cat /proc/net/ipt_hashlimit/synflood2 | wc -l) \
    $(cat /proc/net/ipt_hashlimit/synflood6 | wc -l) \
    $(cat /proc/net/ipt_hashlimit/synflood | wc -l)

#printf "http  conn %6d, syn  %6d \t\tssh conn   %6d, syn %6d\n" \
#    $(ss -tan state established | grep :80 | wc -l) \
#    $(ss -tan state syn-recv | grep :80 | wc -l) \
#    $(ss -tan state established | grep :22 | wc -l) \
#    $(ss -tan state syn-recv | grep :22 | wc -l)

printf "time-wait  %6d \t\t\tclose-wait %6d\n" \
    $(ss -tan state time-wait | wc -l) \
    $(ss -tan state close-wait | wc -l)

printf "cgit #     %6d \t\t\thttpd #    %6d\n" \
    $(ps ax | grep cgit.cgi | wc -l) \
    $(ps ax | grep apache2 | wc -l)

echo

printf "https ipv4 %6d, ipv6 %6d \t\thttp ipv4  %6d, ipv6 %6d\t\t\t(IPs)\n" \
    $(cat /proc/net/ipt_hashlimit/https-limit | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/https-limit | wc -l) \
    $(cat /proc/net/ipt_hashlimit/http-limit | wc -l) \
    $(cat /proc/net/ip6t_hashlimit/http-limit | wc -l)

#printf "ssh   ipv4 %6d, ipv6 %6d\n" \
#    $(cat /proc/net/ipt_hashlimit/ssh-limit | wc -l) \
#    $(cat /proc/net/ip6t_hashlimit/ssh-limit | wc -l)

echo

echo "ipv4  dos_limiter"
iptables -L dos_limiter -n -v | grep -v -E "icmptype (0$|3$|3 code 4$|11$|12$|13$)|syn_flood" | tail -n +2
echo
echo "ipv6  dos_limiter"
ip6tables -L dos_limiter -n -v | grep -v -E "ipv6-icmptype (1$|2$|3$|4$|129$|130.*$|131.*$|132.*$|133.*$|134.*$|135.*$|136.*$|143.*$|148.*$|149.*$|153.*$)|syn_flood" | tail -n +3
echo

echo "ipv4  syn-flood"
iptables -L syn_flood -n -v | tail -n +3
echo
echo "ipv6  syn-flood"
ip6tables -L syn_flood -n -v | tail -n +3
echo

