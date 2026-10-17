---
title: "Ubuntu 26.04 LTSでScanSnap S1100を使う"
author: "sonohen"
date: 2026-10-17
categories: "AI自動日誌"
tags: ["Linux", "Ubuntu"]
draft: false
toc: true
description: "Ubuntu 26.04 LTSでScanSnap S1100のファームウェアとSANEの設定を整え、gscan2pdfでスキャンできることを確認した記録。"
---

ScanSnap S1100をUbuntu 26.04 LTSで使えるようにした。ファームウェアを配置し、SANEの設定を変更したところ、スキャナーとして認識された。gscan2pdfからのスキャンもできたので、当面はこの構成で使うことにした。

## ファームウェアを配置する

まず、今回使用したファームウェア`1100_0A00.nal`をダウンロードした。取得元はGitHubの[stevleibelt/scansnap-firmware](https://github.com/stevleibelt/scansnap-firmware)だ。

```sh
cd ~/Downloads/
wget https://github.com/stevleibelt/scansnap-firmware/raw/refs/heads/master/1100_0A00.nal
ls -alh 1100_0A00.nal
file 1100_0A00.nal
```

`ls`では約65KBのファイルとして表示され、`file`の結果は次のとおりだった。

```text
1100_0A00.nal: data
```

続いて、ファームウェアを`/usr/share/sane/epjitsu/`に配置した。以下は管理者権限で行った操作を、`sudo`付きのコマンドで示している。

```sh
sudo mkdir -p /usr/share/sane/epjitsu/
sudo cp ~/Downloads/1100_0A00.nal /usr/share/sane/epjitsu/
ls -alh /usr/share/sane/epjitsu/1100_0A00.nal
```

配置後は、所有者が`root`、パーミッションが`-rw-r--r--`になっていることを確認した。

## epjitsu.confのファームウェア指定を変更する

設定を編集する前に、`/etc/sane.d/epjitsu.conf`をバックアップした。

```sh
sudo cp /etc/sane.d/epjitsu.conf /etc/sane.d/epjitsu.conf.20261017
```

その後、設定ファイルのファームウェア指定を、配置したファイルのパスへ変更した。今回の記録で、変更前に指定されていたのは次のパスだった。

```text
firmware /usr/share/sane/epjitsu/1100_0B00.nal
```

変更後の有効な指定は次のとおりだ。

```text
firmware /usr/share/sane/epjitsu/1100_0A00.nal
```

`firmware`の指定が対応する`usb`の指定より前にあることも確認した。変更内容はバックアップとの差分で確認できる。

```sh
diff /etc/sane.d/epjitsu.conf /etc/sane.d/epjitsu.conf.20261017
```

今回の差分は次のとおりだった。`<`が編集後の設定、`>`がバックアップの内容になる。

```diff
73,74c73
< # firmware /usr/share/sane/epjitsu/1101_0B00.nal
< firmware /usr/share/sane/epjitsu/1100_0A00.nal
---
> firmware /usr/share/sane/epjitsu/1100_0B00.nal
```

## ScanSnap S1100の認識を確認する

設定後にScanSnap S1100をUbuntuのマシンへ接続し、次のコマンドを実行した。

```sh
scanimage -L
```

結果は次のとおりだった。

```text
device `v4l:/dev/video0' is a Noname Integrated Camera: Integrated C virtual device
device `epjitsu:libusb:001:011' is a FUJITSU ScanSnap S1100 scanner
```

2行目に`FUJITSU ScanSnap S1100 scanner`と表示され、ScanSnapが認識されていることを確認できた。

## gscan2pdfでスキャンする

gscan2pdfを起動し、次の設定でスキャンを試した。

| 項目 | 設定値 |
| --- | --- |
| ページ数 | 全て |
| スキャンプロファイル | Default |
| Postprocessingの認識する言語 | 日本語 |

この状態でスキャンできた。ただし、日本語の文字認識精度までは今回の記録では評価していない。

Windowsでは、実際のドキュメントのサイズに合わせて自動で切り抜く機能を使えていた。今回のLinux環境では、それに相当する設定項目を見つけられなかった。自動切り抜きの方法は確認できていないが、スキャン自体はできるようになったので、まずはこの設定で使ってみる。
