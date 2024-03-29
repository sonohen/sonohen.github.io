---
title: "Windows Subsystem for Linux (WSL) 2への変換"
date: 2020-05-20T14:37:27+0900
author: "sonohen"
categories: [ "技術のこと" ]
tags: [ "技術のこと" ]
---

PowerShellを使用して、WSL(Windows Subsystem for Linux)のバージョンを1から2に変換しました。

<!--more-->

{{< toc >}}

### バージョンの確認

```powershell
PS C:\Users\sonohen> wsl -l -v
  NAME      STATE           VERSION
* Debian    Stopped         1
```

### 変換を試みる

```powershell
PS C:\Users\sonohen> wsl --set-version Debian 2
変換中です。この処理には数分かかることがあります...
WSL 2 を実行するには、カーネル コンポーネントの更新が必要です。詳細については https://aka.ms/wsl2kernel を参照してください
```

以下のURLにアクセスして、`wsl-update_x64.msi`をダウンロードする。

[手順 4 - Linux カーネル更新プログラム パッケージをダウンロードする](https://docs.microsoft.com/ja-jp/windows/wsl/wsl2-kernel)

セットアップが終わったら，再度チャレンジする。

```powershell
PS C:\Users\sonohen> wsl --set-version Debian 2
変換中です。この処理には数分かかることがあります...
WSL 2 との主な違いについては、https://aka.ms/wsl2 を参照してください
Windows の仮想マシン プラットフォーム機能を有効にして、BIOS で仮想化が有効になっていることを確認してください。
詳細については、https://aka.ms/wsl2-install を参照してください
```

そもそもの手順を実施していなかったので実施する。

### 仮想バーチャルマシンサービスのインストール

管理者としてPowerShellを実行する。

```powershell
PS C:\WINDOWS\system32> dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

展開イメージのサービスと管理ツール
バージョン: 10.0.19041.1

イメージのバージョン: 10.0.19041.264

機能を有効にしています
[==========================100.0%==========================]
操作は正常に完了しました。
```

### WSL2を既定のバージョンとして設定する

```powershell
PS C:\WINDOWS\system32> wsl --set-default-version 2
WSL 2 との主な違いについては、https://aka.ms/wsl2 を参照してください
```

これで今後インストールされるWSLはバージョン2となる。

### 変換する

```powershell
PS C:\WINDOWS\system32> wsl --set-version Debian 2
PS C:\WINDOWS\system32> wsl -l -v
	NAME      STATE           VERSION
* Debian    Stopped         2
```
