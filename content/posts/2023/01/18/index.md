---
title: "Ruby on Railsを久しぶりに試してみる"
date: 2023-01-17T15:01:46Z
categories:
  - 技術のこと
tags:
  - 技術のこと
authors:
  - sonohen
draft: true
---

数年振りにRuby on Railsを使ってみた。ただし、使う環境は大きく変わった。

<dl>
<dt>昔の環境</dt>
<dd>Mac OS X + 何かのエディタ</dd>
<dt>今回の環境</dt>
<dd>Chromebook + GitHub CodeSpaces（実態はVSCode Web + Dockerな環境）</dd>
</dl>

<!--more-->

## 環境の準備

コードそのものは以下のリポジトリに入れています。

[sonohen/tutorial_ror](https://github.com/sonohen/tutorial_ror)

## .devcontainer配下の準備

置いてあるファイルは以下の2つ。

1. devcontainer.json
2. Dockerfile

このディレクトリをリポジトリ直下に置いておくと、GitHub CodeSpaces（VSCode for Web）が認識してCodespacesというコンテナを構築してくれる。そこにリモート接続して開発作業が出来るようになるという仕組みです（ざっくり）。

### デフォルトのCodespaceを使わなかった理由

デフォルトでrailsがインストールされていなかったことと、今後、この環境に色々手を入れていくとなったときにDockerfileを自分の管理下に置いておくのが良いと思ったため。

## （ここから）チュートリアル開始

### 事前作業

```shell
# myappという名前のアプリケーションを作成
$ rails new myapp

# とりあえず消しておきたかった
$ cd myapp
$ rm -rf .git/

# 必要なgemのインストール
$ sudo bundle install

# この状態でRuby on Railsのサーバを起動してみる
$ bin/rails server

# アクセスしてもエラーが発生します
# Blocked host sonohen-....github.dev
```

Rails6.0から導入されたDNSリバインディング攻撃（[DNSリバインディング(DNS Rebinding)対策総まとめ](https://blog.tokumaru.org/2022/05/dns-rebinding-protection.html)）への対策によるものです。本当はきちんと対応したほうが良いのですが、とりあえずは以下の対応でお茶を濁しておきます。

```ruby:config/environments/development.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  ...
  config.hosts.clear
  ...
end
```

### Hello World

```shell
# Homeというindexメソッドを持つコントローラーを作成
$ bin/rails generate controller Home index
```

すると、5つのファイルが生成される。

```plain
myapp/app/controllers/home_controller.rb
myapp/app/helpers/home_helper.rb
myapp/app/views/home/index.html.erb
myapp/config/routes.rb
myapp/test/controllers/home_controller_test.rb
```
