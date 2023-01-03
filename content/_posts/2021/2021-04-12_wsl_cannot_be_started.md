---
title: "VS CodeからDebian on WSL2.0にアクセスできずに焦った話"
date: 2021-04-12T19:29:25Z
categories: 
- 技術のこと
tags: 
- 技術のこと
---

本日、VS Codeを立ち上げると、いつもならすぐ繋がるDebian on WSL2.0に接続できなくなりました。原因は不明ですが、WSL2.0をShutdownした後、VS Codeを再度立ち上げ直したところ、無事、接続できました。

<!--more-->

### 発生した問題

VS Codeが出力したエラーメッセージは次の通りでした。`VS Code Server for WSL closed unexpectedly.`と表記されている通り、WSL向けのVS Code Serverへの接続が予期しない理由により切断された、ということです。

```Plain
[2021-04-12 10:24:41.224] Resolving wsl+debian, resolveAttempt: 1
[2021-04-12 10:24:41.302] Starting VS Code Server inside WSL (Debian)
[2021-04-12 10:24:41.302] Extension version: 0.54.6, Windows build: 19042. Multi distro support: available. WSL path support: enabled
[2021-04-12 10:24:41.302] No shell environment set or found for current distro.
[2021-04-12 10:24:41.510] Probing if server is already installed: C:\Windows\System32\wsl.exe -d Debian -e sh -c "[ -d ~/.vscode-server/bin/08a217c4d27a02a5bcde898fd7981bda5b49391b ] && printf found || ([ -f /etc/alpine-release ] && printf alpine-; uname -m)"
[2021-04-12 10:24:41.775] Probing result: found
[2021-04-12 10:24:41.775] Server install found in WSL
[2021-04-12 10:24:41.777] Launching C:\Windows\System32\wsl.exe -d Debian sh -c '"$VSCODE_WSL_EXT_LOCATION/scripts/wslServer.sh" 08a217c4d27a02a5bcde898fd7981bda5b49391b stable .vscode-server 0  '}
[2021-04-12 10:24:41.968] sh: 1: /mnt/c/Users/sonohen/.vscode/extensions/ms-vscode-remote.remote-wsl-0.54.6/scripts/wslServer.sh: Input/output error
[2021-04-12 10:24:41.969] VS Code Server for WSL closed unexpectedly.
[2021-04-12 10:24:41.969] For help with startup problems, go to
[2021-04-12 10:24:41.969] https://code.visualstudio.com/docs/remote/troubleshooting#_wsl-tips
[2021-04-12 10:24:41.981] WSL Daemon exited with code 0
```

### 原因

不明。この事象が発生している時に、Windows TerminalからDebian on WSL2.0にアクセスし、以下のコマンドを発行したところ、エラーが発生した。`cd`の後に`ls`が発行されているのは環境によるものである。[^1]

```shell
% cd /mnt
ls: 'c' にアクセスできません: 入力/出力エラーです
```

[^1]: ~/.zshrcに、`chpwd() { ls -ltr --color=auto }`を登録しているため、cd直後にlsコマンドが発行されている。

### 解決方法

VS Codeを閉じた後、コマンドプロンプトで以下のコマンドを実行し、その後、再度VS Codeを起動する。

```powershell
wsl --shutdown
```

### 参考にしたサイト

- [WSL2 cannot access 'c': Input/output error](https://github.com/microsoft/WSL/issues/6174)
