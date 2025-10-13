+++
title = "Debian GNU/Linux 13 (trixie)の4K出力が安定しない件を解決する"
author = ["sonohen"]
date = 2025-10-13
categories = ["Linux"]
draft = false
toc = true
lead = "Debian GNU/Linux 13 (trixie)とThinkPad E14 (Gen 3)で、外部モニター(JapanNext)への4K出力が安定しなかったので対処しました。"
+++

私は普段、Debian GNU/Linux 13 (trixie)をThinkPad E14 (Gen 3)で運用しており、外付けモニターとしてJapanNextの4Kモニターを使用しています。4K出力に対応しておりながら安価である点が気に入っています。

さて、その環境も、HDMI出力が安定せず、画面が表示されたりされなかったりで作業にならない状況が続いていました。どうもXがEDIDをモニターから取得するまでのタイムラグが原因のように思えましたので、環境決め打ちになってしまうのが気にはなりますが、以下のように対処をしました。

ここに記述している内容はX向けの設定ですが、結果的にXWayland経由で設定が反映されていることになります。


## 問題の切り分け {#問題の切り分け}

まずは物理的な問題を除外しました。

モニター自体は正常か？
: 手元にあるMacBookを使ったところ正常に4K出力できたので、問題は無いと判断した。

HDMIケーブル自体は正常か？
: 手元にあるMacBookに接続してみたところ正常に4K出力できたので、問題は無いと判断した。

ThinkPadのHDMIポートに問題は無いか？
: 手元にある他のモニター(FullHD)に接続してみたところ正常に出力できたので、問題は無いと判断した。

この結果、物理的なハードウェアの問題ではなく、モニターとThinkPadの間の通信(ネゴシエーション)がうまくいかない場合がある、という仮説にいたりました。


## ネゴシエーションの肝となる `EDID (Extended Display Identification Data: 拡張ディスプレイ識別データ)` {#ネゴシエーションの肝となる-edid--extended-display-identification-data-拡張ディスプレイ識別データ}

EDIDは、モニターが自分自身の仕様をコンピュータに伝えるデータです。具体的には以下の情報を含みます。

-   対応解像度(例：1920x1080、3840x2160)
-   リフレッシュレート(例：60hz)
-   色深度やカラーフォーマット
-   製造情報
-   タイミング情報(垂直/水平同期)

通常、コンピュータはEDIDを参照して自動的に最適な解像度やリフレッシュレートを設定します。EDIDのやり取りが失敗すると、画面が表示されなかったり、 `xrandr` が `BadMatch` エラーを返したりします(追記：これは、Waylandで実行すると出るエラーです)。


## モニターから取得したEDID情報をXWayland経由で読み込む {#モニターから取得したedid情報をxwayland経由で読み込む}

つまり、モニターとやり取りをして解像度等を決定するのではなく、あらかじめEDIDを取得しておき、それをXから読み取るようにしておけば、ネゴシエーションに失敗する可能性は低いわけです。ただ問題は、EDIDを取得するためにはきちんと画面出力されている必要があるということで、そこまではなんとかする必要があるということです。全く表示されない場合には、この手段は使えないと思います。


### EDIDを取得する {#edidを取得する}

`/sys/class/drm/card0-HDMI-A-1/edid` からダンプしておきます。ここは環境に依存しますので、どのパスからダンプすればよいのかは `xrandr` の情報を参考にして決めてください。

```shell
$ sudo mkdir -p /etc/X11/edid/
$ sudo cat /sys/class/drm/card0-HDMI-A-1/edid > /etc/X11/edid/JAPANNEXT_JN-280IPS4KR.bin
```


### Xの設定 {#xの設定}

`/etc/X11/xorg.conf.d/10-monitor.conf` を編集します。

```text
Section "Monitor"
   Identifier "HDMI-1"
   Option "CustomEDID" "HDMI-1:/etc/X11/edid/JAPANNEXT_JN-280IPS4KR.bin"
EndSection
```


### ゴミデータの削除 {#ゴミデータの削除}

`~/.config/monitors.xml` が悪さをする可能性があるので、消しておきます。


### Waylandを再起動 {#waylandを再起動}

`sudo systemctl restart display-manager` によりWaylandを再起動し、正常に画面出力されることを確認します。また、HDMIケーブルを何回か抜き差ししても、毎回、安定して画面出力されるかを確認します。


## WaylandネイティブでEDIDを固定する {#waylandネイティブでedidを固定する}

WaylandでもEDIDを固定します。


### `/etc/modprobe.d/edid.conf` を作成する {#etc-modprobe-dot-d-edid-dot-conf-を作成する}

```text
options drm_kms_helper edid_firmware=HDMI-A-1:JAPANNEXT_JN-280IPS4KR.bin
```

その上で、先程作成した `JAPANNEXT_JN-280IPS4KR.bin` を `/lib/firmware/` にコピーしておきます。

その後、initramfsを更新( `sudo update-initramfs -u` )し、再起動します。


## 制約 {#制約}

-   この方法を使うと、HDMI接続時に毎回、JapanNextのEDIDを参照することになるので、他のモニターによっては出力できなくなる可能性があります。環境がある程度固定的であればこの方法は有効ですが、そうでない場合(持ち歩き用途など)では使えない可能性もあります。
-   画面が全く表示されない場合にはEDIDが取得できないため、この方法は使えません。
-   サスペンドからの復旧時には、HDMIケーブルを抜線後にログインし、HDMIケーブルを差し込んだあとXを再起動する必要があります。 `sudo systemctl restart display-manager`
