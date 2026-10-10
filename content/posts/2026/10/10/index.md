---
title: "EmacsでCodexを使う環境を整え、関連書籍を買った日"
author: "sonohen"
date: 2026-10-10
categories: "AI作業日誌"
tags: ["AI", "ChatGPT", "Codex", "Ubuntu", "Linux"]
draft: false
toc: true
description: "EmacsでCodexを使うためにvtermとEatを試し、Docker環境を用意した。日本語入力やAppArmorの設定で悩んだこと、Ubuntuで行った作業、Codex関連書籍を読んで整理した指示の書き方と完了条件を記録する。"
---

今日は、EmacsからCodexを使うための環境を整えていた。CLIのインストールから始めたのだが、ターミナルと日本語入力、Docker、権限の設定まで、思ったより作業が増えた。

## Codexをインストールする

まず、Codexをコマンドラインから使えるようにした。今日の環境では、次のコマンドでインストールしている。

```sh
sudo npm install -g @openai/codex
which codex
```

`which codex`の結果は`/usr/local/bin/codex`だった。

## Emacsではvtermを使うことにした

Codexをインストールしたものの、Emacsのシェルではうまく動かなかった。そこで、vtermを使うためのパッケージを入れた。

```sh
sudo apt install -y cmake libvterm-dev libtool-bin
```

ところが、今回の環境ではvterm上でDDSKKによる日本語入力ができなかった。別のターミナルならどうかと思い、Eatも試してみた。

NonGNU ELPAをパッケージの取得先に追加し、leafで次のように設定した。

```elisp
(leaf eat
  :ensure t
  :bind ("C-c v" . eat-project-other-window))
```

Eatでも日本語入力ができず、動作も安定しなかったため、今回はvtermを使うことにした。DDSKKで入力するという当初の希望は、ひとまず保留にした。これは今日の自分の環境での結果であり、ほかの環境でも同じとは限らない。

## Codex用のDocker環境を作る

次に、CodexをDockerで動かすための環境を作った。Dockerの導入は[公式のUbuntu向けインストール手順](https://docs.docker.com/engine/install/ubuntu/)を参考にした。

インストール後、次のコマンドで確認した。

```sh
sudo docker run hello-world
```

`Hello from Docker!`と表示されたので、続いてCodex用のDockerfileと起動スクリプトを用意した。

イメージのベースには`node:22-bookworm-slim`を使い、Git、ripgrep、PythonなどとCodex CLIをインストールする。コンテナ内では一般ユーザーの`node`で実行し、作業ディレクトリを`/workspace`にした。

起動スクリプトでは、ホスト側の共有ディレクトリを`/workspace`にマウントし、Codexのホームには名前付きボリュームを使った。今日作ったスクリプトを以下に示す。

```sh
#!/bin/sh
set -eu

shared_dir=/home/yma/dockershared
mkdir -p "$shared_dir"

exec docker run --rm -it --init \
  -e TERM \
  -v codex-home:/home/node/.codex \
  --mount "type=bind,src=$shared_dir,dst=/workspace" \
  codex-cli "$@"
```

`shared_dir`は自分の環境のパスなので、別の環境で使う場合は変更する。コンテナから共有ディレクトリ内のファイルは変更できるため、何を共有するかは意識しておきたい。

イメージの作成と起動には、次のコマンドを使った。

```sh
docker build -t codex-cli -f Dockerfile .
./run-codex.sh
```

## bubblewrapとAppArmorの設定で悩む

環境を整える途中で、bubblewrapが新しいnamespaceを作成できないというメッセージにも遭遇した。

まず、次の設定値を確認した。

```sh
sysctl kernel.apparmor_restrict_unprivileged_userns
```

結果は`1`だった。そこで、`/usr/bin/bwrap`に`userns`を許可するAppArmorプロファイルを作り、`apparmor_parser`で読み込んだ。この設定後、私が使っている範囲ではbubblewrap関連のエラーは出なくなった。

また、Codexの`config.toml`には次の設定を追加した。これは今回の環境で追加した内容の記録なので、末尾のパスはインストール先に合わせる必要がある。

```toml
default_permissions = "project-edit"

[permissions.project-edit.filesystem]
":minimal" = "read"
"/usr/local/lib/node_modules/@openai/codex" = "read"
```

[OpenAIのサンドボックスの説明](https://learn.chatgpt.com/docs/sandboxing?surface=app#app-prerequisites)にも、Linuxで必要になるbubblewrapと、UbuntuでのAppArmor設定について記載がある。Ubuntuのバージョンによって扱いが異なるため、同じメッセージが出た場合も、自分の環境に合う手順を確認したい。

## Ubuntuで行ったほかの作業

### aptの段階的な更新を知った

`sudo apt upgrade`を実行したところ、`Not upgrading yet due to phasing`と表示され、20個のパッケージが更新されなかった。

調べると、Ubuntuには更新を一度に全員へ配布せず、対象を段階的に広げる仕組みがある。[Phased updatesの公式説明](https://ubuntu.com/project/docs/how-ubuntu-is-made/concepts/phased-updates/)によると、不具合が見つかった際の影響を小さくするためのものだ。今回の表示は、その段階的な配布に関係していた。

### localsearchを一時的に止めた

`localsearch-extractor-3`の動作が気になったので、ひとまず次のコマンドでサービスを停止し、起動を抑止した。原因はまだ分かっていない。

```sh
systemctl --user mask --now localsearch-3.service
```

実行すると、すぐにプロセスが停止した。元に戻すときのコマンドも記録しておく。

```sh
systemctl --user unmask localsearch-3.service
systemctl --user start localsearch-3.service
```

### ibus-skkを入れた

vtermではDDSKKによる日本語入力ができなかったので、ibus-skkと辞書もインストールした。

```sh
sudo apt install ibus-skk skkdic
```

ところが、vtermとの組み合わせでは変換した文字が消えてしまうなどの問題があり、ibus-skkは使わないことにした。今回の環境では、vterm上の日本語入力はUbuntuのMozcに頼るしかなさそうだ。

## Codexの本を買った

本屋で『Codexではじめるエージェンティックコーディング』を見かけ、タイトルが気になったので購入した。

初版ということもあり、少し誤植が気になる。今後の修正に期待しつつ、読書メモを残しているところだ。

### 指示に目標と完了条件を書く

読書メモには、Mini Codexテンプレートとして、指示に含める4つの項目を整理した。

1. Goal：達成したい目標を書く。
2. Context Pointers：既存の実装や仕様など、参照してほしい情報の場所を示す。
3. Constraints：変更してはいけない仕様や、守るべき規約を書く。
4. Done When：作業が完了したと判断する条件を書く。

AIに必要な情報を渡さなければ、推論や一般的な情報で補われてしまう。自分の作業に必要な文脈を、指示の中に具体的に含めることが大切だと受け取った。

特に完了条件は、実行や確認によって判定できる形にしたい。「きれいなコードにする」よりも、「lintエラーが0件」「既存テストがすべてpassする」のように書く。

### Plan modeを使う場面を考える

Plan modeについては、方向性は決まっていても、詳細を相談しないと完成形が決まらない作業に向いているとメモした。タイプミスの修正や、単一ファイルの文言変更なら、計画を作る手間との釣り合いを考えたい。

計画を確認するときは、目標、参照情報、制約、完了条件に加え、変更の範囲と順序も見る。変更が広がりすぎていないか、戻しやすい単位になっているかを確認する。

また、調査やテスト、小さな変更を先に置き、影響の大きい変更を後にできるかも考える。タスクの分け方を判断するときには、複数の観点で検証できるかを確認したい。


今日はCodexをEmacsから使う準備に多くの時間を使った。vtermを使う方針が決まり、使っている範囲ではbubblewrapのエラーも出なくなった。日本語入力はDDSKKとibus-skkを試したものの、Mozcに頼る方向で考えている。次は、用意した環境で実際の作業を続けながら使い勝手を見ていきたい。
