
# DoS Mitigation

Notes and summary about DoS Mitigation

Also see [Server Connection Limitation and Timeouts](../doc/server-limits_timeouts.md).

## Configuration

### Linux Kernel
Used [sysctl configuration](../05-services/etc/sysctl.d/01-jau_defaults.conf)
- See [archlinux sysctl tuning](https://wiki.archlinux.org/title/Sysctl)

### Firewall

iptables

- Used [ipv4 script](../02-firewall/etc/iptables/ip4tables_bad_fwdmz_good-secure)
- Used [ipv6 script](../02-firewall/etc/iptables/ip6tables_bad_fwdmz_good-secure)

Some references
- [iptables-extensions.8](https://www.man7.org/linux/man-pages/man8/iptables-extensions.8.html)
- [Understanding iptable’s hashlimit module](https://poorlydocumented.com/2017/08/understanding-iptables-hashlimit-module/)
- [Ivan Salloum](https://ivansalloum.com/preventing-syn-flood-attacks-on-your-linux-server/)

#### Monitoring 

The shell script [print-network-stats.sh](scripts/print-network-stats.sh)
prints all interesting metrics from network to iptables stats
as well as overall memory and processes of interest.

~~~~~~~~~~~~~~~~~~~~~~~~~~
watch -n 2 print-network-stats.sh
~~~~~~~~~~~~~~~~~~~~~~~~~~

Following metrics might be of interest
- Per Client IP
  - New Connections (syn-flooding)
    - 5/s http
    - 5/s https
    - 6/s total
  - Concurrent Connections
    - 5 http
    - 5 https

Further the following new-connection limits per IP
are counted
- 1/s total
- 3/s total
- 6/s total

This allows us to estimate the regular connection rate
and adjust the setup.

### Apache

Some references
- [http/2](https://httpd.apache.org/docs/2.4/howto/http2.html)
- [mpm\_event](https://httpd.apache.org/docs/2.4/mod/event.html)

#### Root Apache Server

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/etc/apache2/apache2.conf
    ListenBackLog 5000

a2dismod mpm_prefork
a2enmod mpm_event

a2enmod http2

mods-enabled/http2.conf
 H2Push          off

sites-enabled/001-jausoft_com-ssl.conf
 <VirtualHost *:443>
 Protocols h2 http/1.1

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Bugzilla Apache Server

Bugzilla using `mod_perl` + `mpm_prefork`
saves us lots of CPU + memory.

Hence we have to use a second Apache instance,
forwarded from the root server.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    - a2dismod mpm_event
    - a2enmod mpm_prefork
    - place into vhost config INSTEAD of <Directory /srv/www/jogamp.org/bugzilla>...
        PerlSwitches -w -T
        PerlConfigRequire /srv/www/jogamp.org/bugzilla/mod_perl.pl

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


