---
title: "Git Submoduleを使っている環境で、 upload-pack: not our refエラーが発生した場合の修復方法"
date: 2025-10-08T13:39:47+09:00
draft: false
author: "sonohen"
categories: ["Linux"]
tags: ["Debian", "git"]
keywords: []
description: "Git Submoduleを使っている環境で、Submodule側のpush漏れにより、親が参照するコミットを取得できなくなった際の対処方法を調べました。"
---

# 概要

このブログは、[Hugo](https://gohugo.io/)で構築している。
ブログを構成する資材は全て[GitHub](https://github.com/)に保存しており、以下のような構成になっていた。

```plaintext
blog               <--- Hugoの親リポジトリ(非公開)
 `--- public       <--- 公開用資材のリポジトリ(公開、サブモジュール)
```

この構成により、通常の運用の流れは以下になるはずであった。

1. blogで記事を書き、チェック
2. publicに公開用資材を作成
3. public、blogの両方に対して `git commit` 、`git push` を実行

ところが、前回、別のマシンで作業したときに、3.でpublicに対する `git commit` は実行したものの、`git push`の実行を忘れた状態で、blogに対しても `git commit` 、`git push` したのである。
そのため、以下のような状態になってしまっていた。

```plaintext
blog                     public(submodule)のCommit Hashは BBB であると認識
`--- public(旧マシン)    Commit Hash: BBBをCommit済、未push
`--- public(リモート)    Commit Hash: AAAまでしか存在しない
```

blogは、publicがcommitされた状態(= Commit Hash: BBB)でGitHubのリポジトリに登録されている。
一方で、publicについて、リモート(GitHub)のリポジトリにはCommit Hash: BBBが反映されていない。
つまり、リモートでは、親リポジトリとサブモジュールで一世代分、ずれていたのである。

そのため今回、新マシンで `git submodule update` をしようとしたときに、Commit Hash: BBBのpublicが見付からないということで、`fatal: remote error: upload-pack: not our ref`エラーが発生した。

# 再現手順

1. サブモジュール(public)に変更を加え、`git commit`する(`git push`はしない)。
2. 親リポジトリ(blog)に戻り、サブモジュールを追加(`git add public`)する。
3. 親リポジトリで、`git commit`、`git push`する。
4. その後、別マシンにクローンしてから、以下のコマンドを実行する。

```bash
git submodule update --init
```

すると、以下のようなエラーが出力される。

```text
Cloning into '/home/sonohen/work/blog/blog/public'...
fatal: remote error: upload-pack: not our ref 35b4c8b0165369c2f92485e2b384bfc78827c75f
fatal: Fetched in submodule path './', but it did not contain 35b4c8b0165369c2f92485e2b384bfc78827c75f. Direct fetching of that commit failed.
```

# 対処方法

一世代分の変更を失うことになるが、参照可能なpublicのCommit Hashに戻すことで対応した。

```shell
$ cd public
$ git fetch
$ git checkout 696fc9d1917dbab6789042c72e0b9b904aeb5e6a  # GitHubに存在する最後のCommit Hashを指定

$ cd ../
$ git add public
$ git commit -m "Update submodule ref to valid commit"
$ git push
```

# 今後に向けて

以下のような `deploy.sh` を書いておくことで、サブモジュール側での `commit`、`push` し忘れを防止するようにした。

```shell
#!/bin/bash
set -e

# build site
hugo

# commit using git
cd public
msg="Rebuilding site `date`"
git add -A
git commit -m "$msg"
git push origin master
cd ../

# upload all site settings
git add -A
git commit -m "$msg"
git push origin master
```
