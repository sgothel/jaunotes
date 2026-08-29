
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
- Our custom jail dos-syn and modded `apache-badbots`

## BadBots
It came to our attention that all of the above wasn't enought.

Additionally we need to filter out bad bot requests,
identified by http header as well as known IP addresses.

### Via `User-Agent` and `Sec-CH-UA`
We let `httpd` check the [User-Agent](https://http.dev/user-agent)
and [Sec-CH-UA](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Sec-CH-UA)
http header to deny access from `httpd` as well as to log both details in its log-file,
which is explained in the `Apache2` section below.
An earlier version used header rewrite inside `Apache2`, which wasn't able to deny access and log both details.

The log-files's `User-Agent` and `Sec-CH-UA` header tags are parsed by `fail2ban`
to collect the offending IPs and to block it via the firewall (`nftable`).
Only one header tag is required to match to add the IP block.

The default filter for the `fail2ban` jail `apache-badbots` is out of date
and we had to update it with contemporary `User-Agent` and `Sec-CH-UA` strings,
send by the client in the http header.
[make-bot-list.sh](../02-firewall/etc/fail2ban/scripts/make-bot-list.sh)
fetches [ai-robots-txt](https://github.com/ai-robots-txt/ai.robots.txt)'s
[robots.txt raw file](https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt)
and extracts the names into a file `badbots.txt`.
The latter has to be injected into the `fail2ban` filter
[apache-badbots-jau.conf](../02-firewall/etc/fail2ban/filter.d//apache-badbots-jau.conf)
for our custom `apache-badbots` jail.

To detect bots in the `Sec-CH-UA` tag or in the `User-Agent` tag of the `httpd` logs,
this filter uses the following regexp

~~~~~~~~~~~~~~~~~~
# HOST        DATE                         REQUEST                  REF User-Agent       Sec-CH-UA
# 1.1.1.1 - - [26/Aug/2026:02:56:58 +0200] "GET / HTTP/2.0" 403 533 "-" "Lightpanda/1.0" "\"Lightpanda\";v=\"1\""
failregex = (?i)^<HOST> -[^"]*"(GET|POST|HEAD)[^"]*HTTP.[^"]*" \d+ \d+ "[^"]+" "(?:(?:%(badbots)s|%(badbotscustom)s|%(badbotsupdate)s)|[^"]*" "(?:\"|[^"])*(?:%(badbotsecchua)s))[^"]*".*$
~~~~~~~~~~~~~~~~~~

See below how to configure the extended combined `httpd` log w/ the `Sec-CH-UA`.

The `apache-badbots` jail, may produce millions of `nfttable` set entries (see below),
which renders the `nfttable` hashset operations `list`, `add` and `remove` very **slow**.
However, it seems that the `get` operation is naturally *fast* (hashset).

#### Apache2
At this point, it is a good idea to also filter the bad bots
from the [User-Agent](https://http.dev/user-agent) and
[Sec-CH-UA](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Sec-CH-UA)
http header within [Apache2](https://httpd.apache.org/), where it happens in case `fail2ban` has to be reloaded
and the `nftables` is restored, which may take a long time.

The snippet [bot-filter-rewrite.conf](../05-services/etc/apache2/sites-available/bot-filter-rewrite.conf)
should be updated with above mentioned `badbots.txt` content and be included in the
[site-config](../05-services/etc/apache2/sites-available/jogamp_org-ssl.conf).

~~~~~~~~~~~~~~~~
Include sites-available/bot-filter-rewrite.conf
RewriteRule . - [F,L]
~~~~~~~~~~~~~~~~

`Sec-CH-UA` logging is achieved by using a custom `combined_ext` format as follows

~~~~~~~~~~~~~~
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" \"%{Sec-CH-UA}i\"" combined_ext
CustomLog ${APACHE_LOG_DIR}/jogamp.org-ssl-access.log combined_ext
~~~~~~~~~~~~~~

### Via HTTP Client Hints Usage
[HTTP Client hints](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Client_hints)
beyond `Sec-CH-UA` may be used to further bot detection.

Here is a nice article
[Fight bad bot with Sec Fetch and Client Hints](https://blog.sicuranext.com/sec-fetch-and-client-hints-a-powerful-tool-against-automation/),
and a list of all [user agent client hints](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers#user_agent_client_hints).

Currently this is not yet implemented.

### Via Fixed IP
[make-bot-list.sh](../02-firewall/etc/fail2ban/scripts/make-bot-list.sh)
also fetches a source of known fixed bot ipv6 and ipv4 addresses and networks,
which is being copied to ../02-firewall/etc/iptables
- `badbots_ipv4_ip.txt`
- `badbots_ipv6_ip.txt`
- `badbots_ipv4_net.txt`
- `badbots_ipv6_net.txt`
and used for our firewall setup.

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

## cgit - Web Frontend for Git Repositories
[cgit](https://git.zx2c4.com/cgit/about/) is a web frontend for [Git](https://git-scm.com/)
repositories, written in C.

To tame `cgit` for our tasks running under
[Apache2](https://httpd.apache.org/) with [suEXEC](https://httpd.apache.org/docs/current/suexec.html),
I had to add a few patches on top - which are not merged yet
- My [cgit branch](https://jausoft.com/cgit/cgit.git/log/)

Further I created `cgit-reaper`
- See [cgit-reaper repo](https://jausoft.com/cgit/cgit-reaper.git/about/)

### DoS: Mitigate  lack of `suEXEC` signal Propagation
On our server I exclusively use [suEXEC](https://httpd.apache.org/docs/current/suexec.html)
and DoS bots causing high-resource utilization (load > 10000),
which brought the system w/ ZFS to its knees.

First I set the
[`Apache2` core-config `Timeout = 10`](https://httpd.apache.org/docs/current/mod/core.html#timeout),
which should propagate `SIGTERM` when it has been reached w/o response from the CGI process.
However, the `suEXEC` CGI execution environment does not propagate any signals
to the process running under a different user and environment.

Last resort, setting an explicit `cgit` `timeout=8`
(Giving 2s for Apache2 to detect cgit ended, minimum).
The SIGALRM finally brought down instances taking too long.

My related *impatient* configuration,
considering waiting for a webpage longer than 6s is not realistic:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Apache Timeout is 10s, i.e. cgit to timeout ~2s before minimum (holding bots back)
timeout=8

# limit to 1MB blob-size, i.e. what we transfer to the html UI
max-blob-size=1024

# should happen fast, otherwise server is overloaded
cache-lock-timeout=2000

# if locking the lock-file fails, don't send a newly generated file,
# but HTTP error 429 w/ retry in 42s parameter
cache-lock-fail=429
cache-lock-retry=42

# time delta >= 3s between receives indicates DoS
client-io-idle-timeout=3

# Bps rate < 15k (ISDN decades ago) indicates DoS / Slow-Attack
client-io-min-rate=15000
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The above setup also utilizes previous added mitigations,
i.e. all other configuration regarding lock-failure, io-idle-timeout
and io-min-rate - which also support denying slow-attacks.

Additionally [mod\_reqtimeout](https://httpd.apache.org/docs/current/mod/mod_reqtimeout.html),
may be used to avoid slow attacks,
where I reduced the parameter to similar *impatient* constraints:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
RequestReadTimeout header=2-6,minrate=7000

RequestReadTimeout body=3,minrate=7000
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Hash Optimization

Using a full [64bit FNV-1a hash](http://www.isthe.com/chongo/tech/comp/fnv/)
mitigates collision and can be setup via `cache-size`.
Previous code-base used the 32-bit hash value, wrongly clipped.

A 64-bit hash however leads to the issues of requiring another process to
reap the exceeding files, as we surely don't want to have 2^64 files cached.

This is where [cgit-reaper](https://jausoft.com/cgit/cgit-reaper.git/about/)
comes to use, as it uses a new `cache-max-files` configuration
read from same `cgitrc`.

cgitrc config example:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# new cgit-reaper config (defaults)
pid-parent-dir=/var/run
cache-max-files=1048576
cache-min-ttl=1
cache-max-ttl=525600

# shared cgit/cgit-reaper config (full 64-bit hash)
cache-size=18446744073709551615
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


