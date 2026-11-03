---
author: ["sonohen"]
draft: false
---

## <span class="org-todo done DONE">DONE</span> これはテストです <span class="tag"><span class="test">test</span><span class="emacs">emacs</span></span> {#index}

これはテスト記事です。~ox-hugo~ で書いてみました。


## <span class="org-todo done DONE">DONE</span> Emacs 31にしてからの設定見直し <span class="tag"><span class="_Linux">@Linux</span><span class="Emacs">Emacs</span><span class="macOS">macOS</span></span> {#index}

\*\* 環境

`brew install emacs-app --casks` でインストールした `emacs` を使用している。自分でコンパイルはしていない。

```shell
emacs --version
```

```text
GNU Emacs 31.1
Development version fac653279dcb on HEAD branch; build date 2026-08-24.
Copyright (C) 2026 Free Software Foundation, Inc.
GNU Emacs comes with ABSOLUTELY NO WARRANTY.
You may redistribute copies of GNU Emacs
under the terms of the GNU General Public License.
For more information about these matters, see the file named COPYING.
```

過去の `.emacs` を引っ張り出してきて使おうとしたところ、久し振り過ぎて色々なところで躓いたので、そのときの記録を残すことにした。

\*\* `libgccjit.so` が見つからない

**\*** 警告内容

```plaintext
⛔ Warning (native-compiler): libgccjit.so: error: error invoking gcc driver
```

**\*** 原因

macOSの `gcc` を参照しているため。ネイティブコードにコンパイルするときに `gcc` が `libgccjit` を参照できずにエラーになっている模様。

**\*** 対処

`brew` で `gcc` と `libgccjit` をインストールした。

```shell
% brew install gcc libgccjit
```

その上で `~/.emacs` に以下の記述を追加し `brew` でインストールした `gcc` を呼び出すようにした。

```emacs-lisp
(when (eq system-type 'darwin)
  (setenv "MACOSX_DEPLOYMENT_TARGET" "27.0")
  (let ((brew-prefix "/opt/homebrew"))
    (setenv "PATH" (concat brew-prefix "/bin:" (getenv "PATH")))
    (setq native-comp-compiler-path (concat brew-prefix "/bin/gcc-16"))
    (setenv "LIBRARY_PATH"
            (concat brew-prefix "/lib/gcc/16:"
                    (getenv "LIBRARY_PATH")))))
```

\*\* `Missing 'lexical-binding' cookie` という警告が出力される

**\*** 警告内容

```plaintext
⛔ Warning (files): Missing ‘lexical-binding’ cookie in "~/.emacs.d/elpa/ddskk-20260329.1317/skk-cursor.el".
You can add one with ‘M-x elisp-enable-lexical-binding RET’.
See ‘(elisp)Selecting Lisp Dialect’ and ‘(elisp)Converting to Lexical Binding’
for more information.
```

**\*** 原因

実装による。

**\*** 対処

暫定対処となるが、以下の記述を `~/.emacs` に追記する。

```emacs-lisp
(when (require 'warnings nil t)
  (add-to-list 'warning-suppress-log-types '(files missing-lexbind-cookie)))
```


## <span class="org-todo done DONE">DONE</span> PebbleOS v4.38.2が公開されました <span class="tag"><span class="Pebble">Pebble</span><span class="_Pebble">@Pebble</span></span> {#index}

[Pebble OS v4.38.3が2026年9月24日に公開](https://github.com/coredevices/PebbleOS/releases/tag/v4.38.2)されました。[ChangeLog](https://ndocs.repebble.com/pebbleos-changelog)から変更点を確認することができます。

{{< figure src="/ox-hugo/2026-09-28.PebbleMobileApp.Update.png" caption="<span class=\"figure-number\">Figure 1: </span>アップデート中の様子" width="250px" >}}

個人的に気になる点は次の3点です。

1.  _Initial support for blood oxygen (SpO2) monitoring. Not enabled in Pebble mobile app yet._
2.  _Larger timeline cards. Sports scores and calendar events make better use of the larger displayes._
3.  _Translations are now managed in a community project, making it easier to contribute and keep laguages up to date. Additional languages are delivered as language packs through the mobile app._


## <span class="org-todo done DONE">DONE</span> Pebbleで「あと何歩？」を確認する、Let's Walkingというアプリを開発しました <span class="tag"><span class="_Pebble">@Pebble</span><span class="Pebble">Pebble</span><span class="Walking">Walking</span></span> {#index}

目標までの残り歩数と、折り返しまでの残り歩数を同じ画面に表示する、シンプルなウォーキングアプリです。

{{< figure src="/ox-hugo/2026-10-03.Pebble.letswalking.png" caption="<span class=\"figure-number\">Figure 2: </span>Let's Walkingのウォーキング画面。GOAL LEFTとTURN INを同時に表示" >}}


### 今日の目標に足りない分を歩く {#今日の目標に足りない分を歩く}

設定する目標は、その日の累積歩数です。今回の散歩だけで歩く数ではありません。

例えば、今日すでに3,000歩歩いていて、目標を8,000歩にすると、開始時の残りは5,000歩。その半分の2,500歩を、折り返しの目安にします。半分が端数になる場合は切り上げます。

画面の ****GOAL LEFT**** は目標まで、 ****TURN IN**** は折り返しまでの残り歩数です。この例で1,000歩歩くと、表示はそれぞれ4,000歩と1,500歩になります。折り返し地点は開始時に決まるため、TURN INは、現在のGOAL LEFTを半分にした値ではありません。

折り返しに達すると、一度だけ3回振動し、表示が ****TURN NOW**** に変わります。歩数に基づく目安なので、経路や帰り道を案内する機能はありません。


### 目標を設定して、上ボタンで出発 {#目標を設定して-上ボタンで出発}

アプリを起動したら、右側中央の選択ボタンで目標設定を開きます。

-   上ボタン：100歩増やす
-   下ボタン：100歩減らす
-   選択ボタン：保存する
-   左側の戻るボタン：変更を取り消す

上下のボタンは、押し続けると連続で変更できます。離すと止まり、設定範囲の100〜100,000歩を超えることはありません。初回の目標は8,000歩で、次回からは前回保存した値を使います。

設定を終えたら、開始前の画面で上ボタンを押してウォーキングを開始します。すでに本日の目標を達成している場合は開始せず、 ****ALREADY MET**** と表示します。さらに歩きたいときは、目標を上げてください。


### 休憩は選択ボタン、終了は下ボタン {#休憩は選択ボタン-終了は下ボタン}

歩いている途中で選択ボタンを押すと、中断して **PAUSED** を表示します。もう一度押すと再開します。中断中に増えた歩数は、このウォーキングの進捗から除外します。

目標までの残りが0になると、 ****GOAL MET**** に変わり、折り返しとは別に、一度だけ3回振動します。自動では終了しないので、歩き終えたら下ボタンを押してください。その時点の残り歩数で達成を判定し、結果画面に歩いた歩数と残り歩数を表示します。結果画面で選択ボタンを押すと、次のウォーキングの準備に戻れます。戻るボタンでアプリを閉じます。

日付をまたいでも、開始時を基準にウォーキングは継続します。


### 利用にあたって {#利用にあたって}

Pebble Healthから歩数を取得できる端末が対象で、初代PebbleとPebble Steelは対象外です。画面は英語表示ですが、主な操作は右側のアイコンでも確認できます。

歩数の反映には遅延があり、表示や振動が歩いた瞬間と一致するとは限りません。歩数を取得できない場合は ****NO DATA**** 、そのまま終了した結果は ****UNKNOWN**** （判定不明）と表示します。また、進行中のウォーキングは、アプリの強制終了や端末の再起動後には復元しません。

まずは一日の目標を決めて、残り歩数を見ながら、いつもの散歩に使ってみてください。


### ソースコード {#ソースコード}

MITライセンスで公開しています。

-   [pebble-lets-walking](https://github.com/sonohen/pebble-lets-walking)


## <span class="org-todo done DONE">DONE</span> Ubuntuの通信がNextDNSを経由せずにハマった話 <span class="tag"><span class="_Linux">@Linux</span><span class="NextDNS">NextDNS</span></span> {#index}

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


## <span class="org-todo done DONE">DONE</span> オクトパスエナジーに切り替えた <span class="tag"><span class="_Life">@Life</span></span> {#index}


### 契約切り替えの経緯 {#契約切り替えの経緯}

[オクトパスエナジー](https://octopusenergy.co.jp/)という新興電力会社に切り替えた。

その前は[idemitsuでんき](https://denki.idemitsu.com/)と契約していた。車に乗っていること、近くのガソリンスタンドが出光であること、単価が東京電力よりも若干割安であること、の3つの理由から契約していたのだが、わたしの使い方(日中の在宅が多く、割安な深夜時間帯にはエコキュートくらいしか稼動していない)では、割高な時間帯に電気を使うという矛盾した構図になるのだった。

そんな折、日中(9:00-15:00)に割安になるオクトパスエナジーを知り、idemitsuでんきのウェブサイトから確認できる電力使用量を元にシミュレーションをし、若干割安になる可能性があることから、契約した。


### 現在までの感想 {#現在までの感想}

つい先日切り替わったばかりなので電気代については何とも言えないが、今のところの感想としては次の通りである。


#### 比較的、割安な時間帯に寄せやすい {#比較的-割安な時間帯に寄せやすい}

きちんとシミュレーションをしていたので当然といえば当然であるが、日常で使う電力を割安な時間帯(9:00-15:00)に寄せやすい。普通に生活をしていれば自然と寄っていくし、エコキュートも8時間、時間設定をずらした。

どういうことかというと、元々、我が家のエコキュートは、電力会社が設定する割安な時間帯(1:00-6:00)に湯沸しをするように設定していた。オクトパスエナジーの割安な時間帯とは8時間の時差があることから、エコキュートの日時設定を-8時間して調整したのである。

いままでは深夜に沸かしていたのが日中になったのだから違和感があったが、そんなのは最初の2日もすれば慣れるものである。

どの程度の差があるのかは分からないが、深夜よりも日中のほうが外気温が高いのだから、沸かすのにかかるエネルギーも多少は少なくて済むのではないかと思っている。


#### APIが便利 {#apiが便利}

オクトパスエナジーは外向けにAPIを公開している。実際に、[LINE Messaging APIで電力使用量を通知している開発者の方](https://qiita.com/tsubasa_k0814/items/d7346d19529ca2315fe3)がいらっしゃる。

例にもれず、私もこのAPIを使い、電力使用量と、当月の電力使用状況から月末時点での電気代をシミュレーションするPebbleのアプリケーションを開発し、今、試験しているところである。

idemitsuでんきも過去の電力使用量を表示する契約者専用ページがあるが、APIは公開されていない。オクトパスエナジーは、電力使用量をもとにプログラムを作ることができる点で、開発者にとっては便利である。

今、冷静に考えてみると、何もスマートウォッチで電気代のシミュレーションを見ることもないだろうとは思うものの、せっかくあるわけですし...。


### まとめ {#まとめ}

電気代が安くなるかは正直微妙なところではあるが、最後に書いたAPIは結構遊びがいがありそうなので、しばらく様子を見たいと思う。

ちなみに、オクトパスエナジーの契約を考えている人に向けて、[電気代が8,000円割引になる紹介URL](https://octopusenergy.co.jp/friend/stone-swing-182)をお伝えします。


## <span class="org-todo done DONE">DONE</span> NixOSでZFSからデータを救出する <span class="tag"><span class="_Linux">@Linux</span><span class="NixOS">NixOS</span></span> {#index}


### 概要 {#概要}

Ubuntu Linuxを使用していたが、自分のLinux環境をファイルで定義できるNixOSに興味を持ち、この週末に移行した。
Ubuntu LinuxではLUKSで暗号化したZFSパーティションを使用していたため、NixOSからZFSなパーティションをマウントしてデータ移行する必要があった。その対応の記録をしたので、ブログにまとめることにする。


### 環境 {#環境}

-   NixOS 26.05
-   ThinkPad E14 Gen 3
    -   `/dev/nvme0n1`: KBG40ZNT256G(Toshiba) - NixOSインストール済
    -   `/dev/nvme1n1`: Samsung SSD 980 500GB - Ubuntu Linuxインストール済


### 目的 {#目的}

以下を実現することを目的とする。

-   `/dev/nvme1n1` から `/dev/nvme0n1` に `/home` のデータを移行する
-   `/dev/nvme1n1` を消去し、新たにext4のパーティションを作成し、それをNixOSの `/home` にマウントする


### データ移行の流れ {#データ移行の流れ}

大きくは以下の4つの手順を踏む。

1.  現状の把握
2.  LUKS鍵の取り出し
3.  ZFSパーティションのマウントとデータの移行
4.  ディスクのフォーマットと /home ヘのマウント


### 現状の把握 {#現状の把握}


#### ディスクの状況 {#ディスクの状況}

```sh
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINTS,MODEL
```

```text
NAME        PATH             SIZE TYPE FSTYPE     UUID                                 MOUNTPOINTS MODEL
nvme0n1     /dev/nvme0n1   238.5G disk                                                             KBG40ZNT256G TOSHIBA MEMORY
├─nvme0n1p1 /dev/nvme0n1p1     2G part vfat       E29B-9551                            /boot
├─nvme0n1p2 /dev/nvme0n1p2    24G part swap       15f27874-dfbd-4afb-92cb-56bd089cea04 [SWAP]
└─nvme0n1p3 /dev/nvme0n1p3 212.5G part ext4       ad329431-4846-495f-b312-67d24b2a005c /nix/store
                                                                                       /
nvme1n1     /dev/nvme1n1   465.8G disk                                                             Samsung SSD 980 500GB
├─nvme1n1p1 /dev/nvme1n1p1     1G part vfat       FACF-1404
├─nvme1n1p2 /dev/nvme1n1p2     2G part zfs_member 12601984913637652299
├─nvme1n1p3 /dev/nvme1n1p3     8G part
└─nvme1n1p4 /dev/nvme1n1p4 454.7G part zfs_member 14549146316260236921
```


#### `ZFS` の状態 {#zfs-の状態}

あらかじめ `configuration.nix` に以下の記述を入れたうえでビルドしておく必要がある。

```nix
networking.hostId = "1aeba738";
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
```

なお `networking.hostId` には、以下を実行して取得した値を設定する。

```sh
head -c 8 /etc/machine-id
```

以下のように `nix shell nixpkgs#zfs` を実行すれば環境を汚すこともないので便利である。

```sh
sudo nix shell nixpkgs#zfs -c zpool import
```

無事に認識されていることがわかる。

```text
  pool: bpool
    id: 12601984913637652299
 state: ONLINE
status: The pool was last accessed by another system.
action: The pool can be imported using its name or numeric identifier and
	the '-f' flag.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-EY
config:

	bpool                              ONLINE
	  nvme-eui.002538db11c4531d-part2  ONLINE

  pool: rpool
    id: 14549146316260236921
 state: ONLINE
status: The pool was last accessed by another system.
action: The pool can be imported using its name or numeric identifier and
	the '-f' flag.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-EY
config:

	rpool                              ONLINE
	  nvme-eui.002538db11c4531d-part4  ONLINE
```

ちなみに `rpool` がUbuntu Linuxで言うところの `/` である。


### LUKS鍵の取り出し {#luks鍵の取り出し}

Ubuntu Linuxの `/` をマウントするためのディレクトリとして `/mnt/zfs-recovery/` を作成する。マウントし `rpool` の状態を確認する。

```sh
sudo nix shell nixpkgs#zfs -c zpool import -f -o readonly=on -N -R /mnt/zfs-recovery rpool
sudo nix shell nixpkgs#zfs -c zfs list -r -o name,mountpoint,canmount,encryption,keystatus rpool
```

```text
NAME                                              MOUNTPOINT                                 CANMOUNT  ENCRYPTION   KEYSTATUS
rpool                                             /mnt/zfs-recovery                          off       aes-256-gcm  unavailable
rpool/ROOT                                        none                                       off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3                          /mnt/zfs-recovery                          on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/srv                      /mnt/zfs-recovery/srv                      on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/usr                      /mnt/zfs-recovery/usr                      off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/usr/local                /mnt/zfs-recovery/usr/local                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var                      /mnt/zfs-recovery/var                      off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/games                /mnt/zfs-recovery/var/games                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib                  /mnt/zfs-recovery/var/lib                  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/AccountsService  /mnt/zfs-recovery/var/lib/AccountsService  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/NetworkManager   /mnt/zfs-recovery/var/lib/NetworkManager   on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/apt              /mnt/zfs-recovery/var/lib/apt              on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/dpkg             /mnt/zfs-recovery/var/lib/dpkg             on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/log                  /mnt/zfs-recovery/var/log                  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/mail                 /mnt/zfs-recovery/var/mail                 on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/snap                 /mnt/zfs-recovery/var/snap                 on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/spool                /mnt/zfs-recovery/var/spool                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/www                  /mnt/zfs-recovery/var/www                  on        aes-256-gcm  unavailable
rpool/USERDATA                                    none                                       off       aes-256-gcm  unavailable
rpool/USERDATA/home_lqdl5w                        /mnt/zfs-recovery/home                     on        aes-256-gcm  unavailable
rpool/USERDATA/root_lqdl5w                        /mnt/zfs-recovery/root                     on        aes-256-gcm  unavailable
rpool/keystore                                    -                                          -         off          -
```

`rpool/USERDATA/home_lqdl5w` が `/home` のデータセットであることがわかる。
`KEYSTATUS` が `unavailable` になっているので、 `encryptionroot` を確認する。

```sh
sudo nix shell nixpkgs#zfs -c zfs get -o property,value encryptionroot,keylocation,keyformat,keystatus,mountpoint,canmount rpool
```

```text
PROPERTY        VALUE
encryptionroot  rpool
keylocation     file:///run/keystore/rpool/system.key
keyformat       raw
keystatus       unavailable
mountpoint      /mnt/zfs-recovery
canmount        off
```

Ubuntu Linux では `rpool/keystore/system.key` が存在し、起動時に `/run/keystore/rpool` にマウントされる。

```sh
sudo nix shell nixpkgs#cryptsetup -c cryptsetup open --readonly /dev/zvol/rpool/keystore keystore-rpool
```

以下のコマンドを実行し、確認する。

```sh
lsblk -f /dev/mapper/keystore-rpool
```

```text
NAME           FSTYPE FSVER LABEL          UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
keystore-rpool ext4   1.0   keystore-rpool d18e3c3c-d0fb-4507-94bc-61327e95edc4
```

期待される場所(`keylocation     file:///run/keystore/rpool/system.key`)で参照できるようにマウントする。

```sh
sudo mkdir -p /run/keystore/rpool
sudo mount -o ro,noload /dev/mapper/keystore-rpool /run/keystore/rpool
sudo test -s /run/keystore/rpool
sudo nix shell nixpkgs#zfs -c zfs load-key rpool
```


### ZFSパーティションのマウントとデータの移行 {#zfsパーティションのマウントとデータの移行}

ここまでで rpool を読み込むための鍵を入手できたので `rpool/USERDATA/home_lqdl5w` をマウントする。

```sh
sudo nix shell nixpkgs#zfs -c zpool get altroot rpool
sudo nix shell nixpkgs#zfs -c zfs get mountpoint,canmount,keystatus rpool/USERDATA/home_lqdl5w
```

`keystatus = available`, `canmount = on` であることが確認できる。

```text
NAME   PROPERTY  VALUE              SOURCE
rpool  altroot   /mnt/zfs-recovery  local
NAME                        PROPERTY    VALUE                   SOURCE
rpool/USERDATA/home_lqdl5w  mountpoint  /mnt/zfs-recovery/home  local
rpool/USERDATA/home_lqdl5w  canmount    on                      local
rpool/USERDATA/home_lqdl5w  keystatus   available               -
```

マウントし、内容を確認する。

```sh
sudo mkdir -p /mnt/zfs-recovery/home
sudo nix shell nixpkgs#zfs -c zfs mount rpool/USERDATA/home_lqdl5w
sudo findmnt -S rpool/USERDATA/home_lqdl5w
ls -la /mnt/zfs-recovery/home
```

```text
TARGET             SOURCE                 FSTYPE OPTIONS
/mnt/zfs-recovery/home
                   rpool/USERDATA/home_lqdl5w
                                          zfs    ro,nodev,relatime,xattr,posixac
total 22
drwxr-xr-x   3 root    root    3 Oct  4 09:43 .
drwxr-xr-x   3 root    root 4096 Oct 25 14:33 ..
drwxr-x---+ 32 sonohen 1000   59 Oct 24 23:07 sonohen
```

ここまできたら、あとは `rsync` を使用してデータを救出すればよい。
`/dev/nvme1n1p1` を `/mnt/new-home` にマウントし、 `/home` の全データを `rsync` で移行する。

```sh
sudo mkdir -p /mnt/new-home
sudo mount /dev/nvme1n1p1 /mnt/new-home
sudo nix shell nixpkgs#rsync -c rsync -aHAXx --numeric-ids /home/ /mnt/new-home/
blkid -s UUID -o value /dev/nvme1n1p1
```


### ディスクのフォーマットと /home へのマウント {#ディスクのフォーマットと-home-へのマウント}


#### `rpool` の切り離し {#rpool-の切り離し}

```sh
sudo nix shell nixpkgs#zfs -c zfs unmount rpool/USERDATA/home_lqdl5w
sudo umount /run/keystore/rpool
sudo nix shell nixpkgs#cryptsetup -c cryptsetup close keystore-rpool
sudo nix shell nixpkgs#zfs -c zpool export rpool
```

切り離し後の確認を行う。nvme1n1がマウントされていないことを確認する。

```sh
sudo findmnt -T /
sudo findmnt -T /boot
sudo findmnt -T /home
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS /dev/nvme1n1
```

```text
TARGET SOURCE         FSTYPE OPTIONS
/      /dev/nvme0n1p3 ext4   rw,relatime
TARGET SOURCE FSTYPE OPTIONS
/boot  /dev/nvme0n1p1
              vfat   rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=is
TARGET SOURCE         FSTYPE OPTIONS
/      /dev/nvme0n1p3 ext4   rw,relatime
NAME          SIZE MODEL                 FSTYPE     MOUNTPOINTS
nvme1n1     465.8G Samsung SSD 980 500GB
├─nvme1n1p1     1G                       vfat
├─nvme1n1p2     2G                       zfs_member
├─nvme1n1p3     8G
└─nvme1n1p4 454.7G                       zfs_member
```


#### パーティションを作成する {#パーティションを作成する}

この作業は破壊的であるため、データのバックアップが完了していることを再確認してから実行する。

```sh
sudo nix shell nixpkgs#gptfdisk -c sgdisk --clear --new=1:0:0 --typecode=1:8300 -change-name=1:home /dev/nvme1n1
sudo nix shell nixpkgs#parted -c partprobe /dev/nvme1n1
sudo udevadm settle
sudo wipefs -a /dev/nvme1n1p1
sudo mkfs.ext4 -L home /dev/nvme1n1p1
```

```sh
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS /dev/nvme1n1
```

```text
NAME          SIZE TYPE FSTYPE MOUNTPOINTS
nvme1n1     465.8G disk
└─nvme1n1p1 465.8G part ext4
```


#### `configuration.nix` の修正 {#configuration-dot-nix-の修正}

以下を追記し、リビルドして再起動する。再起動後 `/dev/nvme1n1p1` が `/home` にマウントされていることを確認する。なお、=/dev/nvme1n1p1= (ext4ファイルシステム) のUUIDは `blkid -s UUID -o value /dev/nvme1n1p1` で取得できる。

```nix
fileSystems."/home" = {
  device = "/dev/disk/by-uuid/66cbb556-4c8b-4480-8ec5-b40484996a4b";
  fsType = "ext4";
};
```


#### 後始末 {#後始末}

冒頭で `configuration.nix` に追記した以下の記述は不要なので消す。

```nix
networking.hostId = "1aeba738";
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
```


### 感想 {#感想}

順を追って対応すればなんら難しくはないのだが、面倒臭い作業ではある。当面対応したくはないのだが、また機会がありそうなので、記録しておく。


## <span class="org-todo done DONE">DONE</span> Cachixを使用する <span class="tag"><span class="NixOS">NixOS</span><span class="_Linux">@Linux</span></span> {#index}


### 課題と目的 {#課題と目的}

私の環境では `emacs-unstable-pgtk` と `openlogi` は、更新が入る度にビルドが走る。それはそれで構わないのだが、一方で日常作業をしている裏でリソースを取られるのも少し違う気がした。

そこで、以下のような構成を実装した。

```text
GitHub(master) <--[checkout]-- GitHub Actions(毎週金曜日4:30起動 / Ubuntu) --[push]--> Cachix
    ^                                                                                     |
    `--------[git pull]-------- ThinkPad E14 Gen 3 <--------[nixos-rebuild switch]--------/
```

この構成により、最も時間を要している `emacs-unstable-pgtk` と `openlogi` はGitHub Hosted Runnerでビルドされるので、
ThinkPadで `nixos-rebuild switch --flake ./nixos#thinkpad` を実行したときに、ローカルビルド時間を大幅に短縮できるというのが目論見である。
(ローカルビルドを完全に無くすとは言っていない)


### 日常の運用 {#日常の運用}

以下の通りになる。

-   毎週金曜日4:30 GitHub Actionsが起動する。
    -   `flake.lock` の更新
    -   `emacs-unstable-pgtk` のビルドとCachixへの転送
    -   `openlogi` のビルドとCachixへの転送
    -   `flake.lock` のコミットとリポジトリへのプッシュ
-   毎週土曜日に、ThinkPadで `git pull`, `sudo nixos-rebuild switch --flake ./nixos#thinkpad` を実行。
    -   このタイミングで、 `emacs-unstable-pgtk` や `openlogi` はビルドされず、Cachixからダウンロードされる。


### 実装 {#実装}


#### `configuration.nix` {#configuration-dot-nix}

`cachix.org` からnixバイナリキャッシュを取得するように設定する。

```nix
extra-substituters = [
  "https://<キャッシュ名>.cachix.org"
];

extra-trusted-public-keys = [
  "<キャッシュ名>.cachix.org-1:<公開鍵>"
];
```


#### `flake.nix` {#flake-dot-nix}

ストアパスが一致するように設定する。

```nix
...
outputs = { self, nixpkgs, home-manager, nixvim, openlogi, beancount-mode, emacs-overlay, ... }: {
  packages.x86_64-linux = {
    emacs = self.nixosConfigurations.thinkpad.pkgs.emacs-unstable-pgtk;
    openlogi = self.nixosConfigurations.thinkpad.config.programs.openlogi.package;
  };

  nixosConfigurations = {
    thinkpad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./common/configuration.nix
        ./thinkpad/configuration.nix
        home-manager.nixosModules.home-manager
        openlogi.nixosModules.default

        {
          nixpkgs.overlays = [
            emacs-overlay.overlays.emacs
          ];
        }

        {
          home-manager.sharedModules = [
            nixvim.homeModules.nixvim
          ];

          home-manager.extraSpecialArgs = {
            inherit beancount-mode;
          };
        }

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sonohen = import ./common/home.nix;
        }
      ];
    };
```


#### `.github/workflows/nixos-parts-build.yml` {#dot-github-workflows-nixos-parts-build-dot-yml}

これが毎週金曜日4:30に起動する。

```yml
name: Update and Build NixOS Packages

on:
  schedule:
    - cron: "30 4 * * 5"
      timezone: "Asia/Tokyo"
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: nixos-update-build
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-24.04
    timeout-minutes: 360

    steps:
      - name: Checkout
        uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          ref: master
          persist-credentials: false

      - name: Install Nix
        uses: cachix/install-nix-action@8aa03977d8d733052d78f4e008a241fd1dbf36b3 # v31.10.6
        with:
          extra_nix_config: |
            max-jobs = 1
            cores = 2

      - name: Setup Cachix
        uses: cachix/cachix-action@38b082610b782e7e93e209c35fd730d399dee866 # v17
        with:
          name: sonohen-cachix
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Update flake.lock
        working-directory: nixos
        run: nix flake update

      - name: Build Emacs
        run: |
          nix build ./nixos#emacs \
            --no-link \
            --print-build-logs

      - name: Build OpenLogi
        run: |
          nix build ./nixos#openlogi \
            --no-link \
            --print-build-logs

      - name: Commit and push flake.lock
        run: |
          if git diff --quiet -- nixos/flake.lock; then
            echo "No updates"
            exit 0
          fi

          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

          git add nixos/flake.lock
          git commit -m "chore(nix): update flake.lock"

          git -c http.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 -w0)" \
            push origin HEAD:master
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```


### 結果 {#結果}


#### ビルドの所要時間と容量 {#ビルドの所要時間と容量}

-   `emacs-unstable-pgtk` のビルド時間は、2026-10-30現在の `emacs-unstable-pgtk-31.1` で35分35秒。
-   `openlogi` のビルド時間は、2026-10-30現在の `0.8.19` で27分20秒。
-   Cachixの利用容量は642.6 MiB。
    -   無料で利用できる容量が5.0GiBなので、5~6世代持たせておけばよいかな。


### 今後の課題 {#今後の課題}

neovimをこの構成のなかに入れておくかどうするかを検討する必要がある。次の更新のタイミングで検討することにしたい。


## <span class="org-todo done DONE">DONE</span> CodexをDocker Sandboxに隔離して安全に動かすためのチュートリアル <span class="tag"><span class="_Programming">@Programming</span><span class="Codex">Codex</span><span class="Docker">Docker</span><span class="NixOS">NixOS</span><span class="Generative_AI">Generative-AI</span></span> {#index}


### 課題感 {#課題感}

AIエージェントは、人間やコンピュータから必要な情報を集め、それらと推論に基づいて自律的に計画を立てて、タスクを消化する。これは非常に便利なことであり、日々の仕事や作業の効率が上がっている印象がある。

その一方で、昨今ニュースを賑わせたように、AIエージェントが暴走したときのことを考えたい。本来は見て欲しくないコンピュータ上の情報や、アクセスしてほしくないサイトにアクセスし、その結果として情報漏洩に繋がるケースもありえる。よって、「AIエージェントをどう動かすか」と同じかそれ以上に、「AIエージェントをどこで動かすか」も重要になっている。

さて、「どこで動かすか」は、概ね以下のような考え方があるのではないかと思う。

1.  いつも使用しているコンピュータにAIエージェントをインストールして動作させる。
2.  何も入っていない専用のコンピュータで動作させる。
3.  仮想マシン上で動作させる。
4.  Dockerコンテナ上で動作させる。

1.は、もはや論外と言ってもよいかもしれない。普段遣いの環境で、広い権限を与えて動かすことには、不安がある。
2.は、流行りの方法かもしれない。古いMacBook等を初期化して、その中でAIエージェントを動作させる。
3.は、ホストとAIエージェントを(ほぼ)完全に分離できる一方で、OSの維持が非常に面倒である。
4.は、3.よりは簡易であるものの、AIエージェントが本当に暴走した際にはホスト側のカーネルに触ることができる可能性があるし、3.と同じようにコンテナのメンテナンスの手間がかかる。

今回紹介するDocker Sandboxは、3.と4.の合わせ技のような技術である。つまり、仮想マシンによる隔離と、コンテナのような扱いやすさを組合せ、AIエージェント専用の仮想マシンを手に入れることができる。
(無論、突き詰めればネットワークの分離、共有するファイル、外部との通信のあり方等を検討する必要は残る)


### 検証目的 {#検証目的}

以下の検証を目的とする。ちなみに[]内のキーワードは、[Follow an authenticated request](https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)の箱を指しており、今回の検証でDocker Sandbox全体の概要を掴みたいと思う。

1.  NixOSで、最新のDocker Sandboxを動作させる方法を確立する [SANDBOX MICROVM]。
2.  Codexの認証は、APIキーではなくOAuth認証で行い、既存のサブスクリプションを変更せずとも使用できることを確認する [Model Provider]。
3.  秘密情報をSandbox内部に保存することなく、認証が必要な外部サービスを利用する方法を確認する。そのため、今回はGitHubリポジトリへのアクセスを検証する [Host-side proxy/Credential store]。
4.  Docker Sandboxが予め許可しているドメインに加え、自身が承認したドメインへの通信を許可する方法を確認する [Network Policy]。


### 検証環境 {#検証環境}

-   ****マシン****: ThinkPad E14 Gen 3 (AMD/ 24GB RAM)
-   ****OS****: NixOS 26.05
-   ****sbx (Docker Sandbox)****: 0.50.1


### 検証 {#検証}


#### NixOSで、最新のDocker Sandboxを動作させる方法を確立する [SANDBOX MICROVM] {#nixosで-最新のdocker-sandboxを動作させる方法を確立する-sandbox-microvm}

<!--list-separator-->

-  Docker Sandboxをインストールする

    2026年11月2日現在、最新の[Docker Sandbox](https://github.com/docker/sbx-releases)は `0.50.1` である。一方で、nixpkg(26.05)で配信されているDocker Sandboxは `0.34.0` であり、半年以上前のものである。

    ```sh
    nix search nixpkgs sbx
    ```

    ```text
    * legacyPackages.x86_64-linux.docker-sbx (0.34.0)
      Safe environments for agents
    ```

    そこで、Docker Sandboxは、NixOSをサポートしてはいないものの、Linux (amd64) 向けのバイナリが公開されているので、それを利用する。
    `configuration.nix` に以下を追記する(必要な箇所のみ抜粋)。

    ```nix
    let
      docker-sbx-latest = pkgs.docker-sbx.overrideAttrs (old: rec {
        version = "0.50.1";
        src = pkgs.fetchurl {
          url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux-amd64.tar.gz";
          hash = "sha256-es2HtXlRGbJO+6u3ZBtxRpBoPwRJJMcQrJtLq+dM1UY=";
        };
      });
    in
    {
      # Allow unfree software
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        docker-sbx-latest
      ];

      users.users."<user_name>" = {
        extraGroups = [ "kvm" ];
      };
    }
    ```

    NixOSの再構築を行い、ログオフ後にログインし直して変更を反映する。以下のコマンドを実行してバージョン情報が返ってくれば成功である。

    ```sh
    sbx version
    ```

    ```text
    sbx version v0.50.1 ddb0268d7124b9cf98955d0b08ffd71a0dfcebe4
    ```

<!--list-separator-->

-  動作確認をする

    基本的には、以下のマニュアルに沿って確認していく。

    -   [Install Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install/)
    -   [Codex](https://docs.docker.com/ai/sandboxes/agents/codex/)

    まずはKVMの状態を確認する。

    ```sh
    lsmod | grep kvm
    ```

    ```text
    kvm_amd               249856  0
    ccp                   192512  1 kvm_amd
    kvm                  1421312  1 kvm_amd
    irqbypass              16384  1 kvm
    ```

    `kvm` グループに所属しているかを確認する。

    ```sh
    cat /etc/group | grep sonohen
    ```

    ```text
    wheel:x:1:sonohen
    networkmanager:x:57:nm-openvpn,sonohen
    scanner:x:59:sonohen
    kvm:x:302:sonohen
    ```

    Docker Sandboxを動作させるには、Docker Accountが必須である。そのため、ここでdockerにログインする。

    ```sh
    sbx login
    ```


#### Codexの認証は、APIキーではなくOAuth認証で行い、既存のサブスクリプションを変更せずとも使用できることを確認する [Model Provider] {#codexの認証は-apiキーではなくoauth認証で行い-既存のサブスクリプションを変更せずとも使用できることを確認する-model-provider}

次に、Codexの認証を行う。今回はChatGPTの3,000円プランで進めるためOAuthで認証する。

```sh
sbx secret set openai --oauth
```

とりあえず `~/sbx-codex-work` を作成し、その中でCodexを起動 (`sbx run codex`) してみる。ここで重要なのは、以下の2点であるように思う。

-   Sandbox内からどのサイトにアクセスできるかは、ユーザが制御できること。ここでは「Balanced(一般的な開発用サイト(github.com等)は許可されており、それ以外はユーザによる明示的な許可が必要)」を選択した。
-   ホスト側にある `~/.codex/skills/` は、Sandbox内では使用できないこと。ホスト側の設定やファイルをSandboxに持っていくことはなく、隔離されたCodexからはプロジェクトのフォルダ(起動フォルダと共有設定したリソース)しか参照できない([Codex | Docker Docs](https://docs.docker.com/ai/sandboxes/agents/codex/#configuration))。そのため、 `~/.codex/skills/` はSandbox内で使用することはできず、プロジェクトに保存したものを使うか、ホストの `~/.local/state/sandboxes/sandboxes/agent-skills` に格納されたものを使う。

<!--listend-->

```text
  ✓ started daemon (2s)

Choose the network policy for sandboxes
  1. Open   all network traffic allowed, no restrictions
  2. Balanced   default deny, with common dev sites allowed
  3. Locked Down   all network traffic blocked unless you allow it
Choice [1-3, default 2]: 2

Set network policy Balanced
  try: sbx policy reset
   or: sbx policy allow network HOST
   or: sbx policy deny network HOST
   or: sbx policy rm network HOST

SANDBOX
  Name:       codex-sbx-codex-work
  Agent:      codex
  Workspace:  ~/sbx-codex-work (rw)
  Skills:     0 entries · linked, read-only
    Source:   ~/.local/state/sandboxes/sandboxes/agent-skills
    Target:   /home/agent/.agents/skills
  Image:      docker/sandbox-templates:codex-docker
  CPU:        12
  Memory:     11.2 GiB

IMAGE
  ✓ image — ready
  ✓ OpenAI — using stored OAuth credentials

  ✓ Created sandbox codex-sbx-codex-work

  ○ codex — starting in sandbox codex-sbx-codex-work…
      workspace /home/sonohen/sbx-codex-work
```

その後、見慣れたCodexのTUI画面が表示される。

```text
>_ OpenAI Codex (v0.165.0)
   /home/sonohen/sbx-codex-work
permissions: YOLO mode
```

`YOLO mode` と表示されているとおり、 `codex` は、特に指定しない限り `--dangerously-bypass-approvals-and-sandbox` で起動している。

ここまで終わったら、 `/quit` と入力し、 `codex` を終了(Sandboxから抜ける)しておく。


#### 秘密情報をSandbox内部に保存することなく、認証が必要な外部サービスを利用する方法を確認する [Host-side proxy/Credential Provider] {#秘密情報をsandbox内部に保存することなく-認証が必要な外部サービスを利用する方法を確認する-host-side-proxy-credential-provider}

<!--list-separator-->

-  おおまかな流れ

    まず、どのように認証済リクエストが流れていくかは、[Follow an authenticated request](https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)に記載がある。これによると、秘密情報はSandbox内部ではなくホスト側に保持していることから、Sandbox内の `codex` からは参照できない仕組みになっている。厳密に言えば、秘密情報がSandbox内に保持される場合もあるのだが、それはあくまでもダミー値 (Sentinel) である。実際の値はホスト側の「Credential store」に格納され、「Host-side proxy」によって書き換えられる。今回は、Credential storeにGNOME Keyringが使用されている。

<!--list-separator-->

-  Docker Sandbox内からGitHubにアクセスしてみる

    [Built-in services](https://docs.docker.com/ai/sandboxes/configuration/credentials/#built-in-services)によれば、 `sbx secret set github --command 'gh auth token'` を実行することにより、GitHub CLIの認証情報をCredential storeに格納し、Docker Sandbox内から使用できるようにしてくれる。まずは `gh` (GitHubのCLIクライアント)を使えるようにしなければならないのだが、私は普段、これを使用していない。検証のためにインストールするのもあれなので `nix-shell` で対応する。以下のコマンドをホスト側で実行する。

    ```sh
    nix run nixpkgs#gh auth login
    sbx secret set github --command 'nix run nixpkgs#gh auth token'
    ```

    これが終わったら以下のようなプロンプトを Codex に渡して設定を確認する。

    > \`sbx secret set github\` しました。この設定が正しく行われていることを確認したいので、ためしにリポジトリの一覧を取得してください。

    ただしく設定されていれば、リポジトリの一覧が取得できる。

    > GitHub API への認証に成功しました。ユーザー sonohen として、非公開リポジトリを含む 44 件を取得できています。取得した一覧の一部（更新順）です。
    >
    > | リポジトリ                | 公開設定 |
    > |----------------------|------|
    > | sonohen/sonohen.github.io | 公開 |
    >
    > (以下、省略)

    今回の場合、 `sbx secret set github` した結果は、GNOME Keyringに保管される([Where secrets are stored](https://docs.docker.com/ai/sandboxes/configuration/credentials/#where-secrets-are-stored))。以下のコマンドで確認した。 `9` という数字は環境に依存するので、適宜読み替えていただきたい。

    ```sh
    busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login/9 org.freedesktop.Secret.Item Label
    ```

    ```text
    s "com.docker.sandboxes:sandboxes:docker/sandbox/credentials/_/github"
    ```

    ```sh
    busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login/9 org.freedesktop.Secret.Item Attributes
    ```

    ```text
    a{ss} 4 "id" "docker/sandbox/credentials/_/github" "service:group" "com.docker.sandboxes" "service:name" "sandboxes" "xdg:schema" "org.freedesktop.Secret.Generic"
    ```

    ちなみにこの階層構造は以下のコマンドで確認できる。

    ```sh
    busctl --user tree org.freedesktop.secrets
    ```

    ```text
    └─ /org
      ├─ /org/freedesktop
      │ ├─ /org/freedesktop/portal
      │ │ └─ /org/freedesktop/portal/desktop
      │ │   └─ /org/freedesktop/portal/desktop/request
      │ │     └─ /org/freedesktop/portal/desktop/request/1_48
      │ │       └─ /org/freedesktop/portal/desktop/request/1_48/5B78FD36644BB6B05513F85778626166
      │ └─ /org/freedesktop/secrets
      │   └─ /org/freedesktop/secrets/collection
      │     ├─ /org/freedesktop/secrets/collection/login
      │     │ ├─ /org/freedesktop/secrets/collection/login/1
      │     │ ├─ /org/freedesktop/secrets/collection/login/2
      │     │ ├─ /org/freedesktop/secrets/collection/login/3
      │     │ ├─ /org/freedesktop/secrets/collection/login/4
      │     │ ├─ /org/freedesktop/secrets/collection/login/5
      │     │ ├─ /org/freedesktop/secrets/collection/login/6
      │     │ ├─ /org/freedesktop/secrets/collection/login/7
      │     │ ├─ /org/freedesktop/secrets/collection/login/8
      │     │ └─ /org/freedesktop/secrets/collection/login/9
      │     └─ /org/freedesktop/secrets/collection/session
      └─ /org/gnome
        └─ /org/gnome/keyring
          └─ /org/gnome/keyring/daemon
    ```

    ちなみに、 `gh auth login` した際の認証情報は、今回の環境では `/org/freedesktop/secrets/collection/login/8` に対応していた。

<!--list-separator-->

-  (参考) Sandbox内のCodexに、認証情報が読み込めるか確認した結果

    結論としては、認証情報は読み込めるが、それはダミーの認証情報であり、それを使ってGitHubを操作することはできないというものである。あくまで、実際の認証情報はホスト側のHost-side proxy、Credential Providerによって提供されるというものである。

    プロンプトは以下を指定した。

    ```text
    Sandbox内のCodexから認証情報にアクセスできる？
    ```

    回答は次の通り。

    ```text
    調査できました。Sandbox 内で読めたのはダミーの認証情報で、実際の GitHub トークンはホスト側のプロキシが付与する仕組みです。
    値を表示せず、GET /user で比較した結果です。

    | 通信方法                                  | 結果                   |
    |-------------------------------------------+------------------------|
    | GH_TOKEN を使い、プロキシ経由             | sonohen として認証成功 |
    | 無効なトークンで、プロキシ経由            | 同じく認証成功         |
    | トークンなしで、プロキシ経由              | 同じく認証成功         |
    | GH_TOKEN を使い、明示プロキシを使わず通信 | 401（認証失敗）        |

    Sandbox には起動時から GH_TOKEN が渡されており、gh auth token はその値を返していました。しかし、その値自体では GitHub に認証できません。HTTPS プロキシは gateway.docker.internal:3128 に設定されています。
    Docker の公式説明 (https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)にも、Sandbox 内には代替値（sentinel）を渡し、ホスト側のプロキシが実際の認証情報に置き換えると記載されています。
    つまり、今回の構成は実トークンの窃取を防ぐ効果があります。一方、Codex はプロキシ経由で GitHub の権限を利用できるため、プロンプトインジェクションによる操作の悪用には、トークンの権限制限も必要です。
    なお、ホスト側の保存先が GNOME Keyring かどうかは、今回の Sandbox 内の調査では確認していません。
    ```


#### Docker Sandboxが予め許可しているドメインに加え、自身が承認したドメインへの通信を許可する方法を確認する [Network Policy] {#docker-sandboxが予め許可しているドメインに加え-自身が承認したドメインへの通信を許可する方法を確認する-network-policy}

Network Policyは、Docker Sandbox全体に共通する設定と、個別のSandboxに適用される設定の2つがあり、冒頭で設定したNetwork Policyである `Balanced` は、Docker Sandbox全体に共通する設定である。そのため、どのSandboxからも、基本的な開発用サイトにはアクセスできるが、それ以外にアクセスするためにはユーザの明示的な許可が必要である。例えば、以下のようにBBCから最新のニュースを取得しようとすると失敗する。

```text
BBCから最新のニュースを5件取得して。
```

> BBCのニュース見出しを最新順で確認します。取得できた記事にはリンクも付けます。
> ...
> BBCへのアクセスも403 Forbiddenで拒否され、最新記事を取得できませんでした。記事の見出しやリンクを確認できていないため、5件を正確にお伝えすることはできません。

これは、Network Policyにより、BBCへのアクセスが遮断されていることを示している。実際に拒否されているかどうかを調べるには、以下のコマンドをホスト側で実行して確認する。

```sh
sbx policy approval ls
```

```text
APPROVAL                                              SANDBOX                   TITLE                                        DETAIL                                                                                                                                                 OPTIONS
                                                                            allow (Allow), dismiss (Dismiss)
network:J53qFzroB8iTgn-IwcfkCwRBPAXTuz_xNYBWKjxDMrE   codex-sbx-codex-work      feeds.bbci.co.uk:443                         Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
network:Gm11oDu3PS3dYXROHzzUYqsYsGcWcaNz8hHId1XY5I4   codex-sbx-codex-work      www.bbc.com:443                              Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
network:-lxOnQVAz9ZKBsk6jZKid-TEzjcujY92b6vRalW0PdI   codex-sbx-codex-work      bbc.com:443                                  Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
```

この結果から、 `bbc.com`, `feeds.bbci.co.uk` へのアクセスは許可されていないことが分かる。ここで、3つのドメインについて許可するには、以下のコマンドを実行する。 `network:~~~` には、実際の環境で `sbx policy approval ls` して得られたAPPROVAL IDを指定する。

```sh
sbx policy approval respond network:J53qFzroB8iTgn-IwcfkCwRBPAXTuz_xNYBWKjxDMrE --option allow # feeds.bbci.co.uk:443
sbx policy approval respond network:Gm11oDu3PS3dYXROHzzUYqsYsGcWcaNz8hHId1XY5I4 --option allow # www.bbc.com:443
sbx policy approval respond network:-lxOnQVAz9ZKBsk6jZKid-TEzjcujY92b6vRalW0PdI --option allow # bbc.com:443
```

```text
Recorded answer Allow
Recorded answer Allow
Recorded answer Allow
```

この状態で、もう一度BBCの最新ニュースを取得させる。(プロンプトは先と同じ)
すると、以下の結果が得られる。

> BBCニュースのRSSフィードで確認した最新5件です（公開時刻はUTC、2026年11月3日）。
>
> 1.  ウクライナの支援拠点へのロシア軍の爆撃で26人死亡とキーウが発表 — 01:56
>     記事を読む (<https://www.bbc.co.uk/news/articles/cjy56dndlyz0o?at_medium=RSS&at_campaign=rss>)
> 2.  「Mogging」がコリンズ辞書の今年の言葉に。その意味を知っていますか？ — 01:52
>     記事を読む (<https://www.bbc.co.uk/news/articles/cve8rp085zzjo?at_medium=RSS&at_campaign=rss>)
> 3.  AmazonとTemuで「スターリングシルバー」として販売されたアクセサリーから有害化学物質を検出 — 01:49
>     記事を読む (<https://www.bbc.co.uk/news/articles/cm62yjx4dl0jo?at_medium=RSS&at_campaign=rss>)
> 4.  北朝鮮、63億ドル相当の過去最大級Binanceハッキングへの関与を否定 — 01:23
>     記事を読む (<https://www.bbc.co.uk/news/articles/c6rey4v53exgo?at_medium=RSS&at_campaign=rss>)
> 5.  折りたたみ式iPhoneが完売、Appleは次回入荷時期を示せず — 00:29
>     記事を読む (<https://www.bbc.co.uk/news/articles/c6n8dn457ypko?at_medium=RSS&at_campaign=rss>)

アクセスを許可したドメインは、以下のコマンドで確認できる。膨大なため、ここでは 'bbc' に絞って確認する。

```sh
sbx policy ls --type network --wide | grep bbc
```

許可を取り消すには、以下のコマンドを実行する。

```sh
sbx policy rm network --sandbox codex-sbx-codex-work --resource feeds.bbci.co.uk:443
sbx policy rm network --sandbox codex-sbx-codex-work --resource www.bbc.com:443
sbx policy rm network --sandbox codex-sbx-codex-work --resource bbc.com:443
```

再び、以下のコマンドを実行すると、許可されたドメインにbbc関連が含まれていないことが確認できる。

```sh
sbx policy ls --type network --wide | grep bbc
```


### まとめ {#まとめ}

Docker Sandboxは、AIエージェントを隔離するだけでなく、秘密情報を安全に扱うことができるようにしたり、外部との通信を制御することで危険なサイトへのアクセスを予防したりすることで、
AIエージェントを安全に使えるようにする仕組みである。

今までは、このような仕組みを実現するために `AGENTS.md` を利用したり、ハーネス(AIエージェントを動かす実行環境や制御を行う層)を利用したり、はたまた、Dockerで自前で隔離したり色々な手を使っていたが、それらに代わる、あるいはより強い制御を行うための選択肢にDocker Sandboxはなりうるものと感じた。

ただし、Docker Sandboxでは以下のようなリスクには対応できない。Docker Sandboxを使うからといっても、作業ディレクトリの絞り込み、最小権限、ネットワーク接続先の最小化には引き続き取り組んでいく必要がある。

1.  作業ファイルの改竄や破壊
2.  許可された接続先への意図しない情報送信や不正操作
3.  認証情報を使った不正な操作
4.  Sandbox内での特権操作(AIエージェントは sudo 権限を持ってコンテナ内で動作する)
5.  隔離機構(microVM)自体の脆弱性
