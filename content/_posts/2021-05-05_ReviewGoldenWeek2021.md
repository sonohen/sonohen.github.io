---
title: "2021年のGWを振り返る"
date: 2021/5/5 20:27:56
description: "2021年のゴールデンウイークに実施した内容を振り返りました"
categories: 
- Diary
tags:
- diary
- linux
- Fedora
- emacs
---

毎年毎年、思ったように成果が出ていないので、今年は目標を立てていました。進捗率が思わしくないところはありますが、ある程度は思ったとおりになったので記録。

<!-- more -->

### 2021年のGWの目標

以下の目標を立てていました。

1. 自宅のレッツノートのFedora 33からFedora 34へのアップグレード[^footnote1]
2. レッツノート[^footnote2]のスクロールをまともに動かすようにする
3. OneDriveからの脱却のため、NAS（LANDISK）にファイルを移管する
4. Emacsでeasy-hugo, wanderlust, org-agenda, org-capture, org-roamの設定
5. GnuCashで使っているMySQLのバックアップ自動化
6. 「TCP/IPの絵本」の読了
7. 「ネットワークはなぜつながるのか」の読了
8. 「マスタリングTCP/IP」の読了 

### 実績

1. アップデート完了。不具合として認識しているのは、(1)Virt Managerを使った場合のUSB Redirectionの動作不良（[詳細](https://fedoraproject.org/wiki/Common_F34_bugs#USB_devices_forwarded_from_the_host_to_a_guest_aren.27t_recognized_in_a_libvirt_virtual_machine
)）、(2) Pipewireがレッツノート上で機能しない（音が出ない）、の2点。
2. `systemd`を使用し、サスペンドからレジュームした際に`i2c_hid`を`modprove`するようにした。これが実に快適。
3. `Personal Valut`のほかは、LANDISKに移行完了。同時に、自宅のネットワークに接続している場合、自動で`mount`するように自動化した。
4. いずれも設定完了。
5. 今週末対応予定。
6. 読了。
7. 途中まで読んだ（10%程度）。
8. 未着手。

### 今後実施したいこと

1. 1passwordに月会費を支払っているので、bitwarden等に移行したい。
2. 低レベルプログラミングへの着手。

[^footnote1]: 毎年支払っているOffice 365の年間サブスクリプション（年額約1万3千円程度）を節約するため、徐々にMicrosoftから離れつつあります。
[^footnote2]: CF-SV9を使用中。サスペンドからレジュームした際に、タッチパッドの動作が非常に遅くなり、操作不能になります。
