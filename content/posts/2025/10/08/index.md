---
title: "Git Submoduleを使っている環境で、 upload-pack: not our refエラーが発生した場合の修復方法"
date: 2025-10-08T13:39:47+09:00
draft: false
author: "sonohen"
categories: ["Linux"]
tags: ["Debian", "git"]
keywords: []
description: "Git Submoduleを使っている環境で、Submoduleのcommitを忘れてしまったのでその対処方法を調べました。"
---

Debian GNU/Linux 13が公開されたのを機に、このブログのメンテナンスを進めようと思い、GitHubのリポジトリをローカルにクローンさせ、サブモジュールの中身を引っ張ってこようとしたところ、以下の様なエラーに遭遇してしまった。

```bash
$ git submodule update
```

出力されたエラーは以下の通り。

```text
Cloning into '/home/sonohen/work/blog/blog/public'...
fatal: remote error: upload-pack: not our ref 35b4c8b0165369c2f92485e2b384bfc78827c75f
fatal: Fetched in submodule path './', but it did not contain 35b4c8b0165369c2f92485e2b384bfc78827c75f. Direct fetching of that commit failed.
```

これは前回、 `public` というサブモジュールを `git commit` しなかったことが原因であり、既に当時のマシンは手元にない。サブモジュールの `commit hash` をGitHub側と合わせる必要があるので、以下のような手当をした。

```shell
$ cd public
$ git fetch
$ git checkout <valid_commit_hash>

$ cd ../
$ git add public
$ git commit -m "Update submodule ref to valid commit"
$ git push
```

これで、事象自体は解決したはずである。

# 今後に向けて

以下のような `deploy.sh` を書いておくことで `push` し忘れを防止したいと考えている。

```shell
#!/bin/bash

# build site
hugo -D

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
