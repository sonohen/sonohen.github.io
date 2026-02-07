---
title: "GitHub Pagesに独自ドメインを設定する方法（ムームードメイン + Hugo）"
date: 2026-02-07T00:00:00+0900
author: "sonohen"
categories: ["Blog"]
tags: ["GitHub", "Hugo"]
description: GitHub Pagesで公開しているHugoブログに、ムームードメインで取得した独自ドメインを設定する手順と、ハマりやすいポイントをまとめました。
---

GitHub Pagesでブログを公開していると、`sonohen.github.io`のようなデフォルトのドメインではなく、独自ドメインでアクセスしたくなる。今回、ムームードメインで取得したドメインをGitHub Pagesに設定したので、その手順と遭遇したトラブルについてまとめる。

## 全体の流れ

独自ドメインの設定は、大きく以下の5つのステップで行う。

1. ムームードメインでのネームサーバ設定
2. GitHub側でのドメイン認証
3. CNAMEファイルの作成
4. GitHub側でのDNS設定チェック
5. HTTPS通信の強制

順番に説明していく。

## ムームードメインでのネームサーバ設定

[GitHub公式ドキュメント](https://docs.github.com/ja/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#about-custom-domain-configuration)を参考に、ムームーDNSで以下のレコードを設定する。

| サブドメイン | 種別  | 内容              |
| ------------ | ----- | ----------------- |
| -            | A     | 185.199.108.153   |
| -            | A     | 185.199.109.153   |
| -            | A     | 185.199.110.153   |
| -            | A     | 185.199.111.153   |
| www          | CNAME | sonohen.github.io |

Aレコード4つはApexドメイン（`sonohen.net`）をGitHub PagesのIPアドレスに向けるためのもので、CNAMEレコードは`www`サブドメインをGitHub Pagesに向けるためのものである。

### 確認方法

```shell
% dig www.sonohen.net
```

```text
; <<>> DiG 9.10.6 <<>> sonohen.net
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 46977
;; flags: qr rd ra; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;sonohen.net. IN A

;; ANSWER SECTION:
sonohen.net. 3367 IN A 185.199.109.153
sonohen.net. 3367 IN A 185.199.111.153
sonohen.net. 3367 IN A 185.199.108.153
sonohen.net. 3367 IN A 185.199.110.153

;; Query time: 19 msec
;; SERVER: 2400:4051:4682:c200:32be:3bff:fe4d:9964#53(2400:4051:4682:c200:32be:3bff:fe4d:9964)
;; WHEN: Sat Feb 07 22:47:33 JST 2026
;; MSG SIZE  rcvd: 104
```

## GitHub側でのドメイン認証

`GitHub > Profile > Code, planning and automation > Pages > Add a domain`から、ドメインの認証を行う。指定されたTXTレコードをムームーDNSに登録し、認証を通す。

この認証が行われないと、後続のDNSレコードチェックが失敗するため、必ず先に済ませておく。

## CNAMEファイルの作成

GitHub Pagesが独自ドメインを認識するために、CNAMEファイルをリポジトリに配置する必要がある。

```text
www.sonohen.net
```

Hugoで`stack`テーマを使っている場合は、`themes/stack/static/CNAME`に配置する。こうすることで、ビルド時に公開ディレクトリのルートにCNAMEファイルが生成される。

## GitHub側でのDNS設定チェック

`リポジトリ > Settings > Code and automation > Pages > Custom domain`に独自ドメインを入力すると、GitHubがDNS設定をチェックしてくれる。

このチェックが通るためには、事前に以下の3つが完了している必要がある。

- ネームサーバにA、TXT、CNAMEレコードが追加されていること
- CNAMEファイルが公開され、外部からアクセス可能であること
- GitHubでドメイン認証が完了していること

## HTTPS通信の強制

`リポジトリ > Settings > Code and automation > Pages > Enforce HTTPS`にチェックを入れることで、HTTP通信が無効になり、HTTPS通信が強制される。

## ハマったポイント

設定自体はシンプルだが、2つのトラブルに遭遇した。

### ドメイン認証が通らない

ムームーDNSでTXTレコードを作成する際、ホスト名に`_github-pages-challenge-sonohen.sonohen.net`と入力していた。しかし、ムームーDNSでは`.sonohen.net`が自動的に付与されるため、実際に作成されたホスト名は`_github-pages-challenge-sonohen.sonohen.net.sonohen.net`になっていた。

ホスト名を`_github-pages-challenge-sonohen`に修正することで解決した。

#### 確認方法

```shell
% dig _github-pages-challenge-sonohen.sonohen.net +nostats +nocomments +nocmd TXT
```

```text
; <<>> DiG 9.10.6 <<>> _github-pages-challenge-sonohen.sonohen.net +nostats +nocomments +nocmd TXT
;; global options: +cmd
;_github-pages-challenge-sonohen.sonohen.net. IN TXT
_github-pages-challenge-sonohen.sonohen.net. 3541 IN TXT "ひみつ（でもないが）"
```

### DNSチェックが通らない

`Custom domain`の認証が通らなかった原因は、GitHubが`http://www.sonohen.net/CNAME`にアクセスできなかったためだった。

CNAMEファイルには`www.sonohen.net`を記載しておく必要があり、かつ外部からアクセス可能でなければならない。また、DNSチェックが通っていない時点ではHTTPS通信ができないため、HTTPでアクセスされる点にも注意が必要である。

対処として、以下の手順を踏んだ。

1. CNAMEファイルを作成し、`static/CNAME`に配置
2. サイトをリビルド
3. `http://www.sonohen.net/CNAME`にアクセスできることを確認

## まとめ

GitHub Pagesへの独自ドメイン設定は、DNS設定・ドメイン認証・CNAMEファイル配置・DNSチェック・HTTPS強制の5ステップで完了する。特にムームーDNSでは、ホスト名にドメインが自動付与される仕様に注意が必要だった。
