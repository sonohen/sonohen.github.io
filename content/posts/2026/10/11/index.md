---
title: "サスペンド復帰後にNextDNSが応答しなくなる問題を調べ、自動再起動を設定した"
author: "sonohen"
date: 2026-10-11
categories: "AI作業日誌"
tags: ["Linux", "Ubuntu"]
draft: false
toc: true
description: "Ubuntuのサスペンド復帰後にNextDNSが応答しなくなる症状を調査し、NetworkManagerの接続イベントから自動再起動する仕組みを設定した記録。自動再起動による復旧効果は未確認。"
---

Ubuntuの端末をサスペンドから復帰させると、NextDNSから応答を得られなくなることがあった。そのたびに自分でNextDNSを手動再起動していた。毎回操作するのは面倒なので、Codexに症状の調査と自動再起動の実装を依頼した。

NetworkManagerの接続イベントを受け、約5秒後に稼働中のNextDNSを再起動する仕組みを設定した。内部原因は未特定で、自動再起動による復旧効果は今後確認する。

## 調査した環境

| 項目 | バージョン |
| --- | --- |
| Ubuntu | 26.04.1 LTS |
| Linux Kernel | 7.0.0-38-generic |
| NextDNS CLI | 1.47.3 |
| NetworkManager | 1.54.3-2ubuntu3.1 |
| systemd | 259.5-0ubuntu3.4 |

以下の実装は、NetworkManagerで接続を管理し、NextDNS CLIがsystemdの`nextdns.service`として動作する環境を前提とする。

## Wi-Fiが戻ってもDNS問い合わせは失敗していた

Codexにログ調査を依頼した。10月11日のホストのjournalでは、次の時系列を確認できた。

```sh
journalctl -b -u nextdns -u systemd-suspend -u NetworkManager \
  --since '2026-10-11 09:05:00' --until '2026-10-11 09:35:00' --no-pager
```

| 時刻 | ログで確認した内容 |
| --- | --- |
| 09:17:40 | サスペンドを開始し、Wi-Fiを切断 |
| 09:31:19 | サスペンドから復帰 |
| 09:31:25 | NetworkManagerが`CONNECTED_GLOBAL`を報告 |
| 09:32:24以降 | NextDNSのエンドポイント取得がタイムアウト |
| 09:34:04 | DNS問い合わせのタイムアウトが多数発生 |
| 09:34:13 | 自分でNextDNSを再起動 |
| 09:34:18 | 新しいプロセスがDoH接続を再確立 |

名前解決のエラーには、次の文字列が含まれていた。ログ全文ではなく、識別に必要なメッセージ部分を抜粋している。

```text
doh resolve: context deadline exceeded
```

エンドポイント取得でも、次のエラーが出ていた。

```text
exchange: roundtrip: context deadline exceeded
```

Wi-Fiの接続復旧が報告された後も、同じNextDNSプロセスでDNS問い合わせの失敗が続いていた。この事例では、サービスが落ちたというより、動いたまま上流への通信を回復できていないように見える。

内部原因は未特定で、NetworkManagerの接続状態だけでは外部との通信が正常とは言い切れない。手動再起動後のログではDoH接続の再確立が記録されており、自分でもDNSの実応答を確認した。

[NextDNSの公式リポジトリにあるIssue #699](https://github.com/nextdns/nextdns/issues/699)にも、サスペンド復帰後のDNS問い合わせのタイムアウトが報告されている。こちらはNextDNS 1.37.11とUbuntu 22.04の事例だ。今回と同じ原因とは限らない。

## 接続イベントから再起動する

プロセスが生きたまま応答できなくなる症状には、終了時の再起動を設定するだけでは対応できない。Codexはこの症状に対応するため、NetworkManagerの接続イベントからNextDNSを再起動する構成を実装した。

[NetworkManagerのdispatcher仕様](https://networkmanager.dev/docs/api/latest/NetworkManager-dispatcher.html)では、`up`はインターフェースの接続完了、`vpn-up`はVPNの接続完了を表す。Codexの実装では、この2つを対象にしている。

処理は次の順序で進む。

1. dispatcherが`up`または`vpn-up`を受け取る。
2. NextDNSが稼働中なら、systemd timerを再始動する。
3. timerが約5秒後にサービスを呼び出す。
4. 稼働中のNextDNSを再起動する。

実装には、接続直後の状態が落ち着くまでの猶予として5秒の待ち時間を設けている。外部との通信が復旧したことを確認する処理ではない。

タイマーの待ち時間中に別の接続イベントを受け取ると、待ち時間を設定し直す。そのため、接続イベントが短時間に続いても、最後のイベントから約5秒後にNextDNSを1回だけ再起動する。通常のWi-Fi再接続やVPN接続でも動作するため、サスペンド復帰だけに限定した仕組みではない。再起動時には短時間DNSが途切れる。

## dispatcher、timer、serviceの内容

### 接続イベントを受け取るスクリプト

`/etc/NetworkManager/dispatcher.d/90-nextdns-reconnect`に配置する。

```sh
#!/bin/sh
# NetworkManager dispatcher: coalesce connection activation events.
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
case "${2:-}" in
    up|vpn-up) ;;
    *) exit 0 ;;
esac
# Do not undo an intentional stop of NextDNS.
systemctl is-active --quiet nextdns.service || exit 0
exec systemctl --no-block restart nextdns-reconnect.timer
```

`--no-block`でタイマーの再始動を依頼し、dispatcher内では待たない。`dns-change`には反応しないため、NextDNSの再起動に伴うDNS設定変更が次の再起動を誘発するループを避けられる。

### 5秒後に処理するタイマー

`/etc/systemd/system/nextdns-reconnect.timer`に配置する。

```ini
[Unit]
Description=Delay NextDNS restart after network activation

[Timer]
OnActiveSec=5s
AccuracySec=1s
Unit=nextdns-reconnect.service
```

### NextDNSを再起動するサービス

`/etc/systemd/system/nextdns-reconnect.service`に配置する。

```ini
[Unit]
Description=Restart running NextDNS after network activation

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl try-restart nextdns.service
TimeoutStartSec=45s
```

Codexは`try-restart`を使い、管理者が停止しているNextDNSを勝手に起動しないようにした。

## 実機へのインストール

Codexはインストール用の[install.sh](files/install.sh)も作成した。既存の同名ファイルがあれば停止し、ユニットの検証後に設定を配置する。

同じディレクトリに次の5つを保存すると、インストール・アンインストールのスクリプトを利用できる。

- [90-nextdns-reconnect](files/90-nextdns-reconnect)
- [nextdns-reconnect.timer](files/nextdns-reconnect.timer)
- [nextdns-reconnect.service](files/nextdns-reconnect.service)
- [install.sh](files/install.sh)
- [uninstall.sh](files/uninstall.sh)

保存したディレクトリで、ホストの端末から実行する。

```sh
sudo sh ./install.sh
```

dispatcherはroot所有で実行可能にし、グループやほかのユーザーから書き込めない権限にする。インストールスクリプトでは`0755`、ユニットファイルは`0644`に設定している。

NetworkManager自体の再起動やタイマーの`enable`は不要だ。インストール直後にNextDNSを再起動せず、次の接続イベントから動作する。

Codex環境からはsudo認証できなかったため、自分でホストの別ターミナルからインストールした。

## 検証状況と復帰後の確認

Codexは`sh -n`でシェルの構文を確認し、イベント分岐をモックで検証した。`up`と`vpn-up`では稼働中の場合だけタイマーを操作し、停止中や対象外のイベントでは操作しないことを確認した。

Codexの隔離環境ではsystem busへの接続やソケット設定が制限され、現在のサービス状態の取得と`systemd-analyze verify`は失敗した。モック検証は、実際のsystemdやサスペンド復帰を使った検証ではない。実機へのインストールは済んだ。手動再起動後のDNSの実応答は自分で確認したが、接続イベントによる自動再起動と、その後の名前解決の回復は未確認だ。

次回のサスペンド復帰後には、自分で次のコマンドを実行し、ログと名前解決を確認する。

```sh
journalctl -b -u nextdns-reconnect.service -u nextdns.service --since '-10 min' --no-pager
dig @127.0.0.1 example.org +time=3 +tries=1
getent ahosts example.org
```

`dig`の例は、NextDNSが`127.0.0.1:53`で待ち受ける場合の直接問い合わせだ。待受先が異なる場合は、アドレスとポートを設定に合わせる。`getent`ではOSの通常の名前解決を確認する。

確認したいのは、接続後に自動再起動したログが残り、名前解決も成功することだ。サービスが`active`というだけでは、今回の症状が解消したとは判断しない。

## アンインストール

仕組みをアンインストールするときは、ファイルを保存したディレクトリから次を実行する。

```sh
sudo sh ./uninstall.sh
```

アンインストールスクリプトは配置済みファイルと元の実装を比較し、変更されている場合は削除しない。NextDNS本体の設定は変更しない。
