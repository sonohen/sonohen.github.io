---
title: "Blenderの2回目の起動でウィンドウが透明になる：XWayland経由で回避する"
author: "sonohen"
date: 2026-10-16
categories: "AI作業日誌"
tags: ["Linux", "Ubuntu", "Blender"]
draft: false
toc: true
description: "UbuntuのWayland環境で、Blenderの2回目の起動時にウィンドウが透明になった。XWayland経由での切り分けと、アイコンからも同じ方法で起動するためのSnap版ランチャー設定を紹介する。"
---

UbuntuでBlenderを使っていたところ、1回目は起動するのに、終了して2回目を開くと画面が表示されなくなった。よく見ると、ウィンドウが透明になっているようだった。

今回の環境では、`WAYLAND_DISPLAY`を空にしてXWayland経由で起動すると回避できた。毎回端末から起動するのは不便なので、ユーザー用のランチャーにも同じ指定を追加した。変更後はアイコンからの起動も確認できた。

調査とランチャーの変更はCodexに依頼し、端末とアイコンからの起動確認は自分で行った。Wayland側の表示経路に問題を絞れたが、Blender、GPUドライバー、コンポジターのどこに不具合があるかまでは特定していない。

## 発生環境と症状

| 項目 | 確認した環境 |
| --- | --- |
| OS | Ubuntu 26.04.1 LTS |
| Linux Kernel | 7.0.0-38-generic |
| Blender | Snap版 5.2.2 LTS、revision 7803 |
| デスクトップセッション | Wayland |
| GPU | AMD Lucienne |

最初は起動していないと思ったが、画面が表示されない状態でもプロセスは残っていた。ホストの端末で確認した結果は次のとおりだった。

```sh
pgrep -a -f 'blender|snap-confine'
```

```text
14617 /snap/blender/7803/blender
```

終了ログには1回目の`Blender quit`があり、その直後に次の起動要求も記録されていた。起動要求が届いていないという状態ではなかった。

## 初期設定でも再現し、ログは描画処理まで進んでいた

まず`--debug`で起動したが、画面が使えない状態は変わらなかった。続いて、初期設定で詳細ログを取った。

```sh
blender --factory-startup --debug-all > ~/blender-factory-debug.log 2>&1
```

この条件でも透明なウィンドウになる症状は再現した。ログには、次のようにスプラッシュやメニューの描画処理が記録されていた。関係する行を抜粋する。

```text
menutype_draw: opening menu "WM_MT_splash"
ghost_event_proc: ghost redraw decor 1
screen_refresh_if_needed: set screen
menutype_draw: opening menu "TOPBAR_MT_editor_menus"
```

描画処理まで進んでいたため、起動前に停止しているという見立てを改めた。初期設定でも再現することから、保存済みの設定だけが原因である可能性も下がった。ただし、ログに描画処理があっても、画面に正常に表示されたことまでは意味しない。

## Waylandを無効にすると、2回とも起動できた

次に、初期設定の条件を保ったまま、Waylandを無効にして起動した。以下のコマンドは、Blenderを使っているホストの端末で実行する。

```sh
WAYLAND_DISPLAY="" blender --factory-startup
```

この起動では画面が表示された。一度終了し、同じコマンドで再び起動しても表示できた。

`WAYLAND_DISPLAY`を空にしてX11を使わせる方法は、[Blender公式マニュアルのLinux Windowing Environment](https://projects.staging.blender.org/blender/blender-manual/src/branch/main/manual/getting_started/installing/linux_windowing_environment.rst)にも記載されている。Waylandセッション内では、X11アプリを動かすXWayland経由での起動になる。デスクトップ全体をX11セッションに切り替える必要はない。

| 起動条件 | 結果 |
| --- | --- |
| 通常の起動 | 1回目は表示され、2回目は透明になる |
| `--factory-startup --debug-all` | 透明になる症状が再現した |
| `WAYLAND_DISPLAY=""`と`--factory-startup` | 終了後の再起動を含め、2回とも表示された |

この比較から、今回の問題はWayland側の表示経路にある可能性が高いと判断した。具体的な不具合箇所を直したわけではなく、XWaylandを使う回避策だ。

## アイコンからもXWayland経由で起動する

毎回コマンドを入力せずに済むよう、Snap版のランチャーをユーザー側にコピーし、起動コマンドを変更した。ここからのパスとファイル名は、今回使っていたSnap版のものだ。

コピー先は`~/.local/share/applications/blender_blender.desktop`とする。以下は`XDG_DATA_HOME`を変更していない環境向けの手順で、既存ファイルがある場合は上書きせず内容を確認する。

```sh
mkdir -p ~/.local/share/applications
cp -i /var/lib/snapd/desktop/applications/blender_blender.desktop \
  ~/.local/share/applications/blender_blender.desktop
```

コピーしたファイルをエディターで開き、元の`Exec`行を変更する。

変更前：

```ini
Exec=/snap/bin/blender %f
```

変更後：

```ini
Exec=/usr/bin/env WAYLAND_DISPLAY= /snap/bin/blender %f
```

`Exec`では`env`を実行し、その引数として環境変数を渡す。ファイルを開くための`%f`や、アイコンなどの他の項目はそのまま残す。普段の設定を読み込むため、切り分け用の`--factory-startup`は付けない。

ユーザー側にも同名のファイルを置くのは、元のランチャーと同じdesktop file IDで優先させるためだ。この仕組みは[Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry/latest/file-naming.html)と[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/)に基づく。システム側のランチャーは変更しない。

今回の変更後は、次のコマンドで構文検証とデータベース更新を行い、どちらも成功した。

```sh
desktop-file-validate ~/.local/share/applications/blender_blender.desktop
update-desktop-database ~/.local/share/applications
```

その後、自分でアイコンから起動し、画面が表示されることも確認できた。端末で検証した回避策を、普段の起動にも適用できた。

元に戻す場合は、今回作成したユーザー用の`blender_blender.desktop`を削除する。コピーしたランチャーには、Snap側の将来の変更が自動では反映されないため、Blenderの更新後に起動方法やアイコンが変わった場合は元ファイルと比較する。
