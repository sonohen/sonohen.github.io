---
title: "Hugoをインストールする"
date: 2020-05-06T11:36:53+0900
categories: ["Blog"]
tags: ["Hugo", "Git"]
description: "HugoはGo言語で開発されており、Markdown記法と親和性が高く、高速に動作するサイトジェネレーターツールです。GitHub Actionsと組み合わせることで、リポジトリへのプッシュをトリガーにサイトを生成することができるので、検証がてらブログを作ってみました。"
authors: ["sonohen"]
---

## Hugoを導入する

```bash
$ hugo new site shared/site
$ cd site
$ code config.toml
baseURL = "http://sonohen.github.io/"
languageCode = "ja-JP"
title = "sonohen's tech log"
$ hugo
```

ここの時点で，publicディレクトリーが作られていることを確認する。

## テーマの導入

[Hugo Theme](https://themes.gohugo.io/)にすぐに使えるテーマが掲載されている。

今回は，[Hugo Theme Minos](https://github.com/carsonip/hugo-theme-minos)を利用する。

```bash
$ cd themes/
$ git clone --depth 1 https://github.com/carsonip/hugo-theme-minos
$ code ../../config.toml
theme = "hugo-theme-minos"
paginate = 10
[params]
    smartToc = true
$ hugo
```

## GitHub Pageの設定

1. blogレポジトリを作る
   1. これはprivateレポジトリで良い
2. sonohen.github.ioレポジトリを作る

## Gitの設定

public/は，サブモジュールとして管理する。レポジトリが別なため。

```bash
git submodule add -b master git@github.com:sonohen/sonohen.github.io.git public
```

以下のエラーではまったでござる。

```bash
$ git submodule add -b master git@github.com:sonohen/sonohen.github.io.git public
A git directory for 'public' is found locally with remote(s):
origin        https://github.com/sonohen/sonohen.github.io.git
If you want to reuse this local git directory instead of cloning again from
git@github.com:sonohen/sonohen.github.io.git
use the '--force' option. If the local git directory is not the correct repo
or you are unsure what this means choose another name with the '--name' option.
```

この場合，古いsubmodule情報が".git/"以下に残っていることが原因なので，以下のディレクトリとファイルの中身を確認して，古いファイルを削除してやる必要がある。

1. .git/modules/
2. .git/config

こうならないためには，以下のようにsubmoduleを削除しましょう。

```bash
git submodule deinit <消したいsubmodueへのパス>
git rm <消したいsubmoduleへのパス>
```

## Visual Studio Codeを設定して記事を書く

1. Hugofy（akmittal.hugofy）をインストールする。
2. Hugofy: New Postを選択する。
3. 記事を書く。
4. Hugofy: Buildを選択する。
5. siteとpublicをcommit&pushする。

## 参考

- [[git]git submodule addでエラー「A git directory for ‘[指定モジュール]‘ is found locally with remote(s):」](http://to-developer.com/blog/?p=1970)
