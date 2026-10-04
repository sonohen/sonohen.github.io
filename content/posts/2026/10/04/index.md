---
title: "Ubuntuの通信がNextDNSを経由せずにハマった話"
author: ["sonohen"]
date: 2026-10-04
tags: ["NextDNS"]
categories: ["Linux"]
draft: false
toc: true
description: "2022年に購入したThinkPadを引っ張りだしてきて、Ubuntuをインストールしました。セットアップをしていたところ、どうにもNextDNSとの通信が安定しなかったことから原因調査を進めたところ、ネットワークインタフェースがLAN内のDNSサーバを参照していることが原因でした。"
---

[NextDNSの接続チェックサイト](https://test.nextdns.io/)を参照したところ、以下のようなレスポンスが返ってきました。

```javascript
{
    "status": "unconfigured",
    "resolver": "14.0.9.43",
    "srcIP": "xxx",
    "server": "zepto-tyo-1"
}
```

NextDNSの起動状況等を確認するも、正常に起動している模様。

```shell
% nextdns status
```

```text
running
```

```shell
% nextdns config
```

```text
mdns all
bogus-priv true
setup-router false
auto-activate true
listen localhost:53
max-inflight-requests 256
profile 5d5e67
cache-size 10MB
max-ttl 5s
hardened-privacy false
debug false
control /var/run/nextdns.sock
log-queries false
cache-metrics false
cache-max-age 0s
detect-captive-portals false
use-hosts true
timeout 5s
report-client-info true
discovery-dns
```

```shell
% systemctl status nextdns
```

```text
● nextdns.service - NextDNS DNS53 to DoH proxy.
     Loaded: loaded (/etc/systemd/system/nextdns.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-10-04 20:13:02 JST; 12min ago
 Invocation: 4981df20fedf4c4da23cb644af1c17ca
   Main PID: 57539 (nextdns)
      Tasks: 16 (limit: 22939)
     Memory: 6.8M (peak: 9M)
        CPU: 227ms
     CGroup: /system.slice/nextdns.service
             └─57539 /usr/bin/nextdns run

10月 04 20:13:02 thinkpad-e14-g3 systemd[1]: Started nextdns.service - NextDNS DNS53 to DoH proxy..
10月 04 20:13:02 thinkpad-e14-g3 nextdns[57539]: Starting NextDNS 1.47.3/linux on localhost:53
10月 04 20:13:02 thinkpad-e14-g3 nextdns[57539]: Listening on TCP/127.0.0.1:53
10月 04 20:13:02 thinkpad-e14-g3 nextdns[57539]: Listening on UDP/127.0.0.1:53
10月 04 20:13:07 thinkpad-e14-g3 nextdns[57539]: Activating
10月 04 20:13:07 thinkpad-e14-g3 nextdns[57539]: Connected [2a07:a8c1::]:443 (con=7ms tls=27ms, TCP, TLS13)
10月 04 20:13:07 thinkpad-e14-g3 nextdns[57539]: Connected [2a0b:4341:b02:166:5054:ff:fe53:ab1]:443 (con=9ms tls=23ms, TCP, TLS13)
10月 04 20:13:07 thinkpad-e14-g3 nextdns[57539]: Switching endpoint: https://dns.nextdns.io#167.179.109.118,103.170.232.254,2001:19f0:7001:5e19:5400:2ff:fec8:7b5a,2a0b:4341:b02:166:5054:ff:fe53:ab1
```

`/etc/resolv.conf` は以下の通り。ローカルに向いている...。

```shell
% cat /etc/resolv.conf
```

```text
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients to the
# internal DNS stub resolver of systemd-resolved. This file lists all
# configured search domains.
#
# Run "resolvectl status" to see details about the uplink DNS servers
# currently in use.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 127.0.0.53
options edns0 trust-ad
search .
```

これはもう間違いなくネットワークインタフェースにバインドされているDNSサーバ設定の問題だよなぁと思って調べたところビンゴで、 `192.168.10.1` (デフォルトゲートウェイ)に向いていました。

```shell
% resolvctl status
```

```text
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub
       DNS Servers: 127.0.0.1

Link 2 (enp2s0)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
       DNS Servers: 127.0.0.1
     Default Route: no

Link 3 (wlp3s0)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
       DNS Servers: 192.168.10.1 2409:11:4680:100:8222:a7ff:feb8:e34a
     Default Route: yes
```

ということで、以下のコマンドを実行してDNS設定を変更しました。

```shell
% sudo nmcli connection modify "<SSID>" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes
% sudo resolvectl dns wlp3s0 127.0.0.1
% sudo resolvectl domain wlp3s0 '~.'
```

これで無事、NextDNSに向いてくれました。
