
# DoS Mitigation

Notes and summary about DoS Mitigation using
- Linux kernel [sysctl](https://linux.die.net/man/8/sysctl)
  - Core syn-flood attack mitigation
  - Further optimizations
- [iptables](https://www.netfilter.org/projects/iptables/index.html) and [nftables](https://www.netfilter.org/projects/nftables/index.html)
  - Initial syn-flood and DoS mitigation when it happens
  - Logging events to file for pre-emptive fail2ban mitigation
- [fail2ban](https://github.com/fail2ban/fail2ban)
  - Filtering log files and conditionally adding/removing `nftables` blocking rules
  - Temporarily preemptive blocking after the event
  - Reads our iptables syn-flood and DoS detection and creates blocks (dos-syn jail)
  - Using certain default jails

Also see [Server Connection Limitation and Timeouts](../doc/server-limits_timeouts.md).

## Linux Kernel
Used [sysctl configuration](../05-services/etc/sysctl.d/01-jau_defaults.conf)
- See [sysctl](https://linux.die.net/man/8/sysctl)
- See [archlinux sysctl tuning](https://wiki.archlinux.org/title/Sysctl)

## Firewall

[iptables](https://www.netfilter.org/projects/iptables/index.html)
- Initial syn-flood and DoS mitigation when it happens
- Logging events to file for pre-emptive fail2ban mitigation

Used configuration
- [ipv4 script](../02-firewall/etc/iptables/ip4tables_bad_fwdmz_good-secure)
- [ipv6 script](../02-firewall/etc/iptables/ip6tables_bad_fwdmz_good-secure)

The firewall scripts log to `/var/log/firewall/`.
Automatic conversion to nftables is possible via [xtables-translate](https://www.man7.org/linux/man-pages/man8/iptables-translate.8.html)
and these rules are internally translated and added to `nftable` rules on the kernel side.

Hence the holistic `nftable` conversion steps are as follows
- dump `nftable` to a text file
- transfer comments for documentation purposes
- then simply use the safe `nftable`
  [atomic rule replacement](https://wiki.nftables.org/wiki-nftables/index.php/Atomic_rule_replacement)
  and [scripting](https://wiki.nftables.org/wiki-nftables/index.php/Scripting).

### Logging

Add the following rule to your logging system, e.g. `/etc/rsyslog.conf`.
This leads to have our firwall logging output to be recorded in `/var/log/firewall`.
This location is later used by our custom `fail2ban` filter.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
kern.debug          -/var/log/firewall
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Some references
- [iptables](https://www.netfilter.org/projects/iptables/index.html)
- [nftables](https://www.netfilter.org/projects/nftables/index.html)
- [xtables-translate](https://www.man7.org/linux/man-pages/man8/iptables-translate.8.html)
- [iptables-extensions.8 (man)](https://www.man7.org/linux/man-pages/man8/iptables-extensions.8.html)
- [Understanding iptable’s hashlimit module (Poorly Documented)](https://poorlydocumented.com/2017/08/understanding-iptables-hashlimit-module/)
- [Preventing SYN Flood Attacks on Your Linux Server (Ivan Salloum)](https://ivansalloum.com/preventing-syn-flood-attacks-on-your-linux-server/)

## Fail2Ban

[fail2ban](https://github.com/fail2ban/fail2ban)
- Filtering log files and conditionally adding/removing `nftables` blocking rules
- Temporarily preemptive blocking after the event
- Reads our iptables syn-flood and DoS detection and creates blocks (dos-syn jail)
- Using certain default jails

Our [jail setup](../02-firewall/etc/fail2ban/jail.d/jau-01.conf)
- Blocking whole port range, always
- Default jails sshd, apache-\*, sendmail-\*, dovecot, sieve
- Our custom jail dos-syn and modded apache-badbots

### BadBots
It came to our attention that all of the above wasn't enought.

The default filter for the jail `apache-badbots` is out of date
and we had to update it with contemporart user-agent strings.

[make-bot-list.sh](../02-firewall/etc/fail2ban/scripts/make-bot-list.sh)
fetches [ai-robots-txt](https://github.com/ai-robots-txt/ai.robots.txt)'s
[robots.txt raw file](https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt)
and extracts the names into a file `badbots.txt`.

The latter has to be injected into the filter
[apache-badbots-jau.conf](../02-firewall/etc/fail2ban/filter.d//apache-badbots-jau.conf).

The `apache-badbots` filter (see below), may produce millions of `nfttable` set entries (see below),
which renders the `nfttable` hashset operations `list`, `add` and `remove` very **slow**.
However, it seems that the `get` operation is naturally *fast* (hashset).

#### BadBots Fixed IP Filter

[make-bot-list.sh](../02-firewall/etc/fail2ban/scripts/make-bot-list.sh)
also fetches a source of known fixed bot ipv6 and ipv4 addresses and networks,
which is being copied to ../02-firewall/etc/iptables
- `badbots_ipv4_ip.txt`
- `badbots_ipv6_ip.txt`
- `badbots_ipv4_net.txt`
- `badbots_ipv6_net.txt`
and used for our firewall setup.

#### Apache2

At this point, it is also a good idea to also filter the bad bots to
`Apache2` where it happens in case `fail2ban` has to be reloaded
and the `nftables` is restored, which may take a long time.

The snippet [bot-filter-rewrite.conf](../05-services/etc/apache2/sites-available/bot-filter-rewrite.conf)
should be updated according to above procedure and included in the
[site-config](../05-services/etc/apache2/sites-available/jogamp_org-ssl.conf).

## Monitoring

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

## Haskell/Lightpanda Incident

Besides JogAmp, Haskell also had a [very notable incident](https://mailman.haskell.org/archives/list/ghc-devs@haskell.org/thread/AKWY3G76BMMOS6CNV5PZ64PHNWGDK3MM/)

> - 1.4 Million distinct IPv4 addresses have been used with this bot user agent
> - the IP addresses stem from 225 different countries. I think we have ~ 30 more distinct ISO country codes.
> - we have some known faces! like spacex which got flagged 100% time on their 21000 distinct IP addresses they're using to DDoS us
> - we also have quite a lot of domestic use ASNs, which indicates that botnets are involved, too!
> - Xe noted, that we can proudly say this counts as a DDoS

The perpetrator used `Lightpanda`, see [their issue 3156](https://github.com/lightpanda-io/browser/issues/3156).
After checking our JogAmp logs .. tada, over 550k banned IPs so far
and new IP entries are added by the second.
The `fail2ban` sqlite database these offender consumes roughly 450MB.

It has to be noted, that this is a distributed DoS (DDos) attack.
The culprit doesn't act from one IP, which could be easily detected
and handled - but from a wide range of machines.

The abuse by these AI users are biting the hand they feed
- ignoring `robots.txt` by default!
- abusing server to the point where one could give up, content is gone
- wasting small resources and energy only for their AI training


## Apache

Some references
- [http/2 (apache)](https://httpd.apache.org/docs/2.4/howto/http2.html)
- [mpm\_event (apache)](https://httpd.apache.org/docs/2.4/mod/event.html)

### Root Apache Server

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

### Bugzilla Apache Server

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


