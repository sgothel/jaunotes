# Server Connection Limitation and Timeouts

## Recommendations
- [Qualsys Recommendations](https://blog.qualys.com/vulnerabilities-threat-research/2011/11/02/how-to-protect-against-slow-http-attacks)
  - Apache
    - `Limit` to set reasonable request limit in bytes
    - `KeepAliveTimeout` and `Timeout`, see below
    - ...

## Connection Limit

### [Apache](https://httpd.apache.org)
Apache uses [Multi-Processing Modules (MPMs)](https://httpd.apache.org/docs/2.4/mpm.html).
- [worker](https://httpd.apache.org/docs/2.4/mod/worker.html)
- prefork, event ..

Relevant settings ...
- [MPM Common](https://httpd.apache.org/docs/2.4/mod/mpm_common.html)
  - [ServerLimit](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#serverlimit)
    - Upper limit on configurable number of processes
    - Hard limit 20'000 in general or 200'000 for prefork MPM

Behavior for exceeding connections seems to be being
pushed into the [ListenBacklog](https://httpd.apache.org/docs/2.4/mod/mpm_common.html#listenbacklog)
with a default of 511, which then may or may not timeout or gets served.

Overall exceeding connections are seemingly not served, i.e. dropped.

### [NGINX](https://nginx.org/en/)
- [Module ngx\_http\_limit\_conn\_module](https://nginx.org/en/docs/http/ngx_http_limit_conn_module.html)
  - `limit_conn` limit the number of connections to the server per zone, e.g. client IP, URL, ..
  - `limit_conn_status` response to rejected requests, defaults to 503 (Service Unavailable, temporary state)

### Linux Kernel

#### General
The default memory bound upper limit
for concurrent TCP connections on Linux is 4 per MB system-memory,
see `Linux Kernel` below, e.g.
- 4096M -> 16384
- 16384M -> 65536
- 65407M -> 262144

- [IP Systctl] MaxConnections (https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html)
  - `tcp_max_orphans`
    - Maximal number of free non-file TCP sockets before resetting them. Each orphan eats up to ~64K of unswappable memory.
    - 4 per MB system-memory (memory bound)
- [Netfilter Conntrack](https://www.kernel.org/doc/html/latest/networking/nf_conntrack-sysctl.html)
  - `nf_conntrack_max`
    - Defaults to `nf_conntrack_buckets`
    - 4 per MB system-memory (memory bound)

## Keep-Alive and Timeouts

Recurring default magic timeouts are
- http general
  - 60s to complete receiving client request
- http keep-alive
  - 5s to 75s max idle period until next request
  - 100 to 1000 maximum requests for each connection

### Custom Application
- `DefaultTimeout` 64s
  - Maximum duration to complete a http client request
  - Maximum socket poll duration (internal poll-timeout, not leading to disconnection)

- `InactivityTimeoutMax` 3600s
  - Maximum socket inactivity (usually a http StreamSocket) between client activity (I/O data)
  - Prevents against `slow attack`

- `MinTransferRate` 500 Bps
  - Minimum transfer rate to client using total time and transfered bytes.
  - Prevents against `slow attack`

- `PingPeriodMax` 18s
  - WebSocket (WS) ping period (not leading to disconnection on failure)

### [Apache](https://httpd.apache.org)
- [Module Code](https://httpd.apache.org/docs/2.4/mod/core.html)
  - [MaxKeepAliveRequests](https://httpd.apache.org/docs/2.4/mod/core.html#maxkeepaliverequests)
    - 100 default, requests allowed on a persistent connection
  - [KeepAliveTimeout](https://httpd.apache.org/docs/2.4/mod/core.html#keepalivetimeout)
    - 5s default until subsequent request before closing the connection
  - [Timeout](https://httpd.apache.org/docs/2.4/mod/core.html#timeout)
    - 60s default completion time for a client request.
- [Module mod\_reqtimeout](https://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html)
  - [RequestReadTimeout](https://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html#requestreadtimeout)
    - Timeout values for completion of TLS handshake, receiving client request header/body
      including throughput minimum rate

### [NGINX](https://nginx.org/en/)
- [Module Core](https://nginx.org/en/docs/http/ngx_http_core_module.html)
  - [keepalive\_timeout](https://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_timeout)
    - 75s default during which a keep-alive client connection will stay open on the server side
      (until the next request).
  - [keepalive\_time](https://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_time)
    - 1h default maximum time during which requests can be processed through one keep-alive connection.
  - [keepalive\_requests](https://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_requests)
    - 1000 default number of requests that can be served through one keep-alive connection
  - [client\_header\_timeout](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_header_timeout)
    - 60s default to transmit complete header.
    - Fails with http 408 (request time-out).
  - [client\_body\_timeout](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_body_timeout)
    - 60s default period between two successful read operations (client requests?).
    - Fails with http 408 (request time-out).
  - [client\_max\_body\_size](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)
    - 1MB default allowed client request body size.
    - Failes with http 413 (Request Entity Too Large)

### Linux Kernel
- [IP Systctl] KeepAlive (https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html)
  - `tcp_keepalive_time`
    - 2h default staying alive..
  - `tcp_keepalive_probes`
    - defaults to 9 failed messages, i.e. failure threshold
  - `tcp_keepalive_intvl`
    - 75sec default interval


## ICMP Ping
[World Ping Test - global ping test](https://www.meter.net/tools/world-ping-test/)
for ICMP ping, demonstrates latency of < 500ms (Germany to Sydney w/ ~333ms).

## WebSockets Ping Latency and Timeouts

Fixed maximum ping latencies values ranging between 10s-120min for the timeout, leaning towards the low-end.
- 5s: [node.js default server.keepAliveTimeout](https://betterstack.com/community/guides/scaling-nodejs/nodejs-timeouts/)
- 20s: [Python WebSockets](https://websockets.readthedocs.io/en/latest/topics/keepalive.html)
- 20s: [grpc](https://github.com/grpc/grpc/blob/master/doc/keepalive.md)

Fixed KeepAlive intervals and timeouts
- 30s: [.Net](https://learn.microsoft.com/en-us/dotnet/api/system.net.websockets.websocket.defaultkeepaliveinterval?view=net-8.0)
- 30-150s: [Zato's websocket-timeouts](https://zato.io/en/blog/websocket-timeouts.html)

### Robust Threshold Ping Timeout
[Zato's websocket-timeouts](https://zato.io/en/blog/websocket-timeouts.html)
uses a missed ping threshold (default 5) and above timeout (=interval) (default 30s),
allowing for package-loss scenarios.

Zato actually uses a default of `5 * 30s = 150s`, exceeding all above mentioned timeout defaults.

Proposed is a more tight but still above used defaults `(5-1) * 9s  + 8s = 44s`,
i.e. threshold of 5 and an _moving_ average timeout of 8s and interval of 9s.

Such instrument gives following robust properties
- Allows to miss `threshold - 1` pings (package-loss),
- Resets the timeout criteria if one pong has been received
- Essentially expands the timeout to `(threshold-1) * interval + avg_timeout`, i.e. `(5-1) * 9s  + 8s = 44s`
  - `avg_timeout` being the _moving_ average timeout for a single ping (default 8s)
  - threshold being the number of pings to fail before timeout (default 5)
  - interval being >= `avg_timeout`, period until next ping attempt (default 9s)
  - Note: If any value is zero, the instrument is disabled

## Summary

### Connection Limit
While Apache2 seems to silent out exceeding connection limits, NGINX may reply with a http status 503 (Service Unavailable, temporary state).
Depending on the actual limitation, such a reply is sensible if below the OS threshold of swapping out memory (200k) probably.

Currently Linux application's 4/MB-sysmem connection limit (262k on 64GB) is a hard limit to silent out (drop) connections.
Perhaps a 2/3rd fraction of such could be used to deliver mentioned 503 http status in case of newly requested http sessions.
This would introduce a lower threshold for new http requests to be nicely rejected.

### Timeout

Please see above fine grained keep-alive and timeout values.

