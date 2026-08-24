#!/bin/bash

sdir=`dirname $(readlink -f $0)`

filter_ipv4_ip() {
    grep -E -o -e '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' $1
}
filter_ipv4_net() {
    grep -E -o -e '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,3}' $1
}
filter_ipv6_ip() {
    grep -E -o -e '([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}' $1
}
filter_ipv6_net() {
    grep -E -o -e '([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}/[0-9a-fA-F]{1,4}' $1
}

# IPs first
echo "Creating general addresses.net.list"
cp ${sdir}/addresses.net.list.orig ${sdir}/addresses.net.list
${sdir}/update-bot-addresses.sh

# echo "Creating Apache ip-bot-filter-require.conf"
# sed 's/^\([0-9]\)/Require not ip \1/' ${sdir}/addresses.net.list > ${sdir}/ip-bot-filter-require.conf

echo "Creating badbots.txt user-agent pattern"
rm -f ${sdir}/robots.txt
curl -o ${sdir}/robots.txt https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt
grep User-agent ${sdir}/robots.txt | awk ' BEGIN { ORS="|" } { print $2 }' > ${sdir}/badbots.txt

# cp -v ${sdir}/ip-bot-filter-require.conf ${sdir}/../../05-services/etc/apache2/sites-available/
cp -v ${sdir}/badbots.txt ${sdir}/../../02-firewall/etc/fail2ban/

echo "Creating ${sdir}/../../02-firewall/etc/iptables/badbots_ipv[46]_(ip|net).txt"
filter_ipv4_ip  ${sdir}/addresses.net.list > ${sdir}/../../02-firewall/etc/iptables/badbots_ipv4_ip.txt
filter_ipv6_ip  ${sdir}/addresses.net.list > ${sdir}/../../02-firewall/etc/iptables/badbots_ipv6_ip.txt
filter_ipv4_net ${sdir}/addresses.net.list > ${sdir}/../../02-firewall/etc/iptables/badbots_ipv4_net.txt
filter_ipv6_net ${sdir}/addresses.net.list > ${sdir}/../../02-firewall/etc/iptables/badbots_ipv6_net.txt

