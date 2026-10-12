---
title: "DockerのAppArmor適用失敗：プロファイルの読み込みとreadby権限で対処"
author: "sonohen"
date: 2026-10-12
categories: "AI作業日誌"
tags: ["Linux", "Ubuntu"]
draft: false
toc: true
description: "UbuntuでCodex用Dockerコンテナが起動できなかった原因を、AppArmorの拒否ログから調査。カスタムプロファイルの読み込みとreadby権限の追加、ホストへの配置、適用結果の確認を説明する。"
---

UbuntuでCodex用のDockerコンテナを起動したところ、AppArmorプロファイルの適用に失敗した。原因は、起動時に指定したカスタムプロファイルがホストに読み込まれていなかったことだった。読み込むとコンテナは起動したが、続いてコンテナ内のbubblewrapで権限不足が見つかり、プロファイルの修正も必要になった。

この記事では、Dockerを使う技術者に向けて、拒否ログによる切り分けと対処を説明する。今回確認した問題は次の2段階だった。

| 発生段階 | ログの手掛かり | 対処 |
| --- | --- | --- |
| コンテナの起動時 | `label not found` | 指定したプロファイルをホストに読み込む |
| 起動後のbubblewrap実行時 | `denied_mask="readby"` | 同じプロファイルのプロセス間に`readby`を許可する |

調査はCodexに依頼し、ホストの設定変更とコマンド実行は自分で行った。修正後はコンテナへのプロファイル適用を確認し、提示した直近5分のログに拒否はなかった。その後、ホストの再起動後も自分で確認し、問題なかった。

## この環境でのAppArmorとbubblewrapの役割

AppArmorは、プロセスが実行できる操作をプロファイルで制限するLinuxのセキュリティ機構だ。今回の環境では、Dockerコンテナに`codex-bwrap`というカスタムプロファイルを適用していた。これは自分の環境で用意した名前で、Docker標準のプロファイル名ではない。

コンテナ内では、Codexのコマンド実行を制限するためにbubblewrap（実行ファイル名は`bwrap`）も使っている。コンテナが起動した後も、その中のプロセスはAppArmorの制約を受けるため、bubblewrapの動作に必要な操作をプロファイルで許可する必要がある。

また、プロファイルには次の3つの状態がある。設定ファイルがあるだけでは、コンテナに適用できない。

| 状態 | 今回の対象・確認方法 |
| --- | --- |
| 設定ファイルが存在する | `~/work/codex-docker/codex-bwrap.apparmor` |
| ホストのLinux Kernelに読み込まれている | `apparmor_parser`で読み込み、`aa-status`で確認 |
| コンテナに適用されている | `docker inspect`の`AppArmorProfile`で確認 |

以下のコマンドは、Dockerデーモンが動いているUbuntuホストの通常のユーザー端末で実行する。パスとプロファイル名は自分の環境に合わせて読み替える必要がある。掲載するルールは既存プロファイルの変更箇所であり、プロファイル全体ではない。

## 発生したエラーと環境

実行したのは、自作のCodex用Docker起動スクリプトだ。このスクリプトは、コンテナの起動時に`codex-bwrap`を指定する。

```sh
~/work/codex-docker/run-codex.sh
```

出力は次のとおりだった。末尾のヘルプ案内は省略している。

```text
Docker AppArmor setting: codex-bwrap
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: unable to apply apparmor profile: apparmor failed to apply profile: write fsmount:fscontext:proc/thread-self/attr/apparmor/exec: no such file or directory
```

`unable to apply apparmor profile`から、コンテナを準備するOCIランタイムがAppArmorを適用する段階で失敗したと分かる。コンテナ内のCodexは、まだ動き始めていなかった。調査時に確認した環境は次のとおり。

| 項目 | バージョン・状態 |
| --- | --- |
| Ubuntu | 26.04.1 LTS |
| Linux Kernel | 7.0.0-38-generic |
| Docker Client / Server | 29.9.0 / 29.9.0 |
| Docker context | default |
| containerd | v2.4.1 |
| runc | 1.5.2 |
| AppArmor parser | 5.0.2 |
| AppArmor | 有効、`codex-bwrap`を指定 |

## 起動時の拒否ログから、プロファイル未読み込みを確認する

エラー末尾は`no such file or directory`だが、Codexが確認すると、ホストの`/proc/thread-self/attr/apparmor/exec`は存在していた。

原因を判断する手掛かりになったのは、Linux Kernelのログだった。

```sh
sudo aa-status | rg 'codex-bwrap'
sudo journalctl -k -b --no-pager --grep='codex-bwrap|label not found' -n 30
```

`aa-status`の抽出結果に`codex-bwrap`の行はなく、ログには次の拒否が記録されていた。時刻やホスト名などを省略し、メッセージ部分を抜粋している。

```text
apparmor="DENIED" operation="change_onexec" class="file" info="label not found" error=-2 profile="runc" name="codex-bwrap" pid=8853 comm="runc:[2:INIT]"
```

ここでいうラベルは、AppArmorがプロファイルを識別するための名前だ。`name="codex-bwrap"`と`info="label not found"`から、起動時に指定したプロファイルを見つけられなかったと分かる。[runc 1.5.2の実装](https://raw.githubusercontent.com/opencontainers/runc/v1.5.2/libcontainer/apparmor/apparmor_linux.go)では、exec属性への書き込みでプロファイルを指定する。今回の書き込みエラーは、パス自体が存在しないという意味には限定できなかった。

Codexが起動スクリプトを調べたところ、AppArmorを自動選択する`CODEX_APPARMOR=auto`設定は、DockerのAppArmor対応だけを確認していた。カスタムプロファイルの登録確認や読み込みは行っていなかった。[Dockerの公式資料](https://docs.docker.com/engine/security/apparmor/)でも、カスタムプロファイルは先に読み込み、その後でコンテナに指定する手順になっている。

今回の`aa-status`と拒否ログを合わせると、指定したプロファイルをホストに読み込む必要があった。ただし、以前の登録が再起動などで失われたのか、別の理由で未読み込みだったのかは特定できていない。

## プロファイルを読み込んで起動エラーを解消した

Codexがプロファイルの実ファイルを確認し、自分で次のコマンドを実行した。`apparmor_parser`は設定ファイルを解析してホストに読み込むコマンドで、`-r`は既存のプロファイルがあれば置き換える指定だ。

ここではファイルの場所が明確になるよう、絶対パスを使っている。管理者権限の実行環境では、`$HOME`が通常ユーザーのホームを指すとは限らない。

```sh
sudo apparmor_parser -r -W /home/sonohen/work/codex-docker/codex-bwrap.apparmor
sudo aa-status | rg 'codex-bwrap'
```

実行した結果、`apparmor_parser`の終了コードは0となり、`aa-status`にも`codex-bwrap`が表示された。コンテナの`docker inspect`でも同じプロファイル名を確認でき、元のOCI起動エラーは解消した。

## 起動後の拒否ログから、readby権限を追加する

コンテナへの適用を確認した後、Linux Kernelのログに別の拒否が出ていた。`comm="bwrap"`はbubblewrapのプロセスを示す。最初の起動エラーが解消しても、プロファイルの内容が実行時の操作に足りるとは限らなかった。

```text
apparmor="DENIED" operation="ptrace" class="ptrace" profile="codex-bwrap" pid=11588 comm="bwrap" requested_mask="readby" denied_mask="readby" peer="codex-bwrap"
```

当時のプロファイルには、次のルールがあった。

```text
ptrace (read, trace) peer=codex-bwrap,
```

このログでは、`profile`と`peer`がともに`codex-bwrap`で、拒否された権限は`readby`だ。同じプロファイルが適用されたプロセス同士のアクセスで、読まれる側の許可が不足していた。

AppArmorの`ptrace`ルールは、デバッガによる操作に加え、一部の`/proc`経由のプロセス情報へのアクセスも制御する。`read`は相手の情報を読む側、`readby`は相手に読まれる側の許可を表す。[Ubuntu 26.04のAppArmorマニュアル](https://manpages.ubuntu.com/manpages/resolute/man5/apparmor.d.5.html)でも、アクセスする側と受ける側の双方に許可が必要とされる。同じプロファイルのプロセス間でも、`read`だけでは足りなかった。

Codexの提案に従い、元ファイル`/home/sonohen/work/codex-docker/codex-bwrap.apparmor`の該当ルールを次のように変更した。

```text
ptrace (read, readby, trace) peer=codex-bwrap,
```

許可対象は`peer=codex-bwrap`のままにした。今回の拒否ログでは`tracedby`は要求されていないため、追加していない。

## 修正版をホストへ配置し、再起動後も読み込めるようにする

`apparmor_parser`による読み込みは、現在動いているLinux Kernelに対する操作だ。再起動後も読み込めるよう、修正版のファイルをホストのAppArmor設定ディレクトリ`/etc/apparmor.d/codex-bwrap`へ配置した。

作業時には、初回の配置で宛先ファイルが存在しないことを確認していた。その後の`readby`追加では、配置済みのファイルをバックアップしてから更新した。以下の掲載例は、既存ファイルがある場合だけバックアップする形にまとめている。

バックアップは`/var/backups`に置く。元の作業手順では`/etc/apparmor.d`内に置いていたが、[AppArmor 5.0.2の実装](https://gitlab.com/apparmor/apparmor/-/raw/v5.0.2/libraries/libapparmor/src/private.c)では、`.bak-日時`は読み込みの除外対象にならない。古いファイルも読み込み対象になり得るため、掲載例では配置先を変更した。

```sh
sudo install -d -m 0700 /var/backups/codex-apparmor
if [ -f /etc/apparmor.d/codex-bwrap ]; then
  sudo cp -a /etc/apparmor.d/codex-bwrap \
    /var/backups/codex-apparmor/codex-bwrap.bak-$(date +%Y%m%d-%H%M%S)
fi
sudo install -m 0644 /home/sonohen/work/codex-docker/codex-bwrap.apparmor \
  /etc/apparmor.d/codex-bwrap
sudo apparmor_parser -r -W /etc/apparmor.d/codex-bwrap
sudo aa-status | rg 'codex-bwrap'
```

ホストのポリシー変更、配置、再読み込みは自分で実施した。Codexは元ファイルの`readby`追加と、配置済みファイルとの一致を読み取りで確認した。

## 適用結果と再起動後の確認

配置と再読み込みが終わったら、コンテナを起動して適用結果を確認する。自作スクリプトの`CODEX_APPARMOR=required`は、AppArmorを必須にする設定だ。作業対象のディレクトリで次を実行する。

```sh
CODEX_APPARMOR=required ~/work/codex-docker/run-codex.sh
```

起動後、別の端末から対象コンテナと拒否ログを確認する。

```sh
docker ps
docker inspect --type container --format '{{.AppArmorProfile}}' CONTAINER_ID
sudo journalctl -k --since '5 minutes ago' --no-pager \
  --grep='codex-bwrap|apparmor="DENIED"'
```

`CONTAINER_ID`には、`docker ps`で確認した実際のIDを指定する。期待する結果は、コンテナが起動し、`AppArmorProfile`が`codex-bwrap`となり、対象の操作時に新しい拒否ログが出ないことだ。確認に5分以上かかる場合は、`--since`の範囲を起動時刻まで広げる。

自分が提示した修正後の結果では、`docker inspect`の出力は`codex-bwrap`だった。直近5分のログには次の更新通知だけがあり、`DENIED`はなかった。メッセージ部分を抜粋する。

```text
apparmor="STATUS" operation="profile_replace" profile="unconfined" name="codex-bwrap" pid=12838 comm="apparmor_parser"
```

ここにある`profile="unconfined"`は、更新を行ったプロセス側の表示だ。コンテナに適用されたプロファイルは`docker inspect`の結果で確認した。

ここまでの適用結果とログは調査記録に残っている。再起動後の自動読み込みは、その記録をまとめた時点では未確認だったが、その後、自分でホストを再起動して確認し、問題なかった。

ただし、当初行おうとしていたCodexの具体的な操作の成否は、調査記録には残っていない。コンテナ起動とAppArmor適用の確認だけで、Codexの全機能が動作したとは判断していない。また、修正後に拒否がなかったという判断は、提示したログの時間範囲に基づく。

## 同じ症状を調べるときの確認順序

今回の調査では、エラー末尾の`no such file or directory`だけでは原因を判断できなかった。Linux Kernelのログでラベル解決失敗を確認し、読み込み後には別の権限不足を切り分けた。同じ症状を調べる場合は、次の順序で確認すると、今回の2つの問題を区別できる。

1. `aa-status`と起動時の拒否ログで、指定したプロファイルが読み込まれているか確認する。
2. 起動できたら、`docker inspect`でコンテナへの適用を確認する。
3. 対象の操作を実行し、新しい拒否ログの`profile`、`peer`、`denied_mask`から不足している許可を調べる。
