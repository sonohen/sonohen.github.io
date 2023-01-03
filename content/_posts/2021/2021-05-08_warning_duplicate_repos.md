---
title: "dnfでRepository is listed more than once in the configurationが表示された場合の対応"
date: 2021-05-08T20:45:53Z
categories: 
- "技術のこと"
tags:
- "技術のこと"
---

`dnf update`を実行した際に、`Repository 1password is listed more than once in the configuration`という警告メッセージが表示されたので調査した。

結論としては、`/etc/yum.repos.d/`の配下に別名で、中身が（ほぼ同じ）ファイルが2つ存在したための警告メッセージであったため、重複しているものを無効にすることでメッセージの出力を抑制した。

<!--more-->

```c {linenos=table,hl_lines=[6]}
#include <stdio.h>

int
main() {
    printf("Hello World!\n");
    return 0;
}
```

aaa

```shell
$ ls -alh /etc/yum.repos.d/
合計 60K
drwxr-xr-x. 1 root root 664 5月 8 19:48 .
drwxr-xr-x. 1 root root 5.3K 5月 8 19:51 ..
-rw-r--r--. 1 root root 190 4月 28 21:29 1password-beta.repo
-rw-r--r--. 1 root root 210 5月 7 01:01 1password.repo
-rw-r--r--. 1 root root 311 1月 26 14:48 _copr_phracek-PyCharm.repo
-rw-r--r--. 1 root root 728 4月 29 02:31 fedora-cisco-openh264.repo
-rw-r--r--. 1 root root 1.3K 4月 29 02:31 fedora-modular.repo
-rw-r--r--. 1 root root 1.4K 4月 29 02:31 fedora-updates-modular.repo
-rw-r--r--. 1 root root 1.4K 4月 29 02:31 fedora-updates-testing-modular.repo
-rw-r--r--. 1 root root 1.4K 4月 29 02:31 fedora-updates-testing.repo
-rw-r--r--. 1 root root 1.3K 4月 29 02:31 fedora-updates.repo
-rw-r--r--. 1 root root 1.3K 4月 29 02:31 fedora.repo
-rw-r--r--. 1 root root 173 5月 8 19:48 google-chrome.repo
-rw-r--r--. 1 root root 1.5K 1月 26 14:48 rpmfusion-nonfree-nvidia-driver.repo
-rw-r--r--. 1 root root 1.4K 1月 26 14:48 rpmfusion-nonfree-steam.repo
-rw-r--r--. 1 root root 148 5月 1 21:00 skype-stable.repo
-rw-r--r--. 1 root root 154 5月 1 21:02 teams.
```

なぜか1passwordのrepoが2つ存在している。ので、これのうち一つをどこかに移してしまえば良さそう。というわけで、どちらを残すのか中身を確認してみる。

```diff
$ diff 1password.repo 1password-beta.repo
2,3c2,3
< name="1Password Beta Channel"
< baseurl=https://downloads.1password.com/linux/rpm/beta/$basearch
---
> name=1Password
> baseurl=https://downloads.1password.com/linux/rpm/beta/x86_64
7c7
< gpgkey="https://downloads.1password.com/linux/keys/1password.asc"
---
> gpgkey=https://downloads.1password.com/linux/keys/1password.asc
```

細かい差分はさておき、注目すべき差分は `1password.repo` の `$basearch` である。 ここで、 `$basearch` には `x86_64` が入る（see [6.3.3 Yum 変数の使用](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_yum_variables)) ということなので、つまり2つのファイルに差分は見受けられない。

ゆえに、`1password for Linux` はbeta版であるので、`/etc/yum.repos.d/1password-beta.repo`を残す方針とする。

```bash
$ sudo mv 1password.repo 1password.repo.old
$ sudo dnf update
メタデータの期限切れの最終確認: 1:56:41 時間前の 2021年05月08日 18時22分17秒 に実施しました。
依存関係が解決しました。
行うべきことはありません。
完了しました!
```


ついでに、`/etc/yum.repos.d/google-chrome.repo`も削除しておいた（Firefoxに移行したため）。
