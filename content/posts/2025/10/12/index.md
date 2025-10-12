+++
title = "Debian GNU/Linux 13 (trixie)でSwiftを動かす"
author = ["sonohen"]
date = 2025-10-12
draft = false
toc = true
lead = "Debian GNU/LinuxでSwiftを動かしてみようという試みをしました。"
+++

`Swift` は、Apple社が開発をしているプログラミング言語で、主にApple製品で動作させるソフトウェアを開発するために使用されるものですが、オープンソース化されてからというもの、Linuxなどサーバサイドで動作するソフトウェアの開発にも使われているようです。

今回は、たまたま目新しいということで、インストールしてみました。


## Swiftをインストールする {#swiftをインストールする}

[Install Swift](https://www.swift.org/install/linux/)を参考にすればインストール自体は簡単にできます。

```shell
$ cd
$ mkdir swiftly
$ cd swiftly
$ curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz
$ tar xvzf swiftly-$(uname -m).tar.gz
$ sudo ./swiftly init --quiet-shell-followup
$ sudo apt install libstdc++-12-dev     # Swiftlyからインストールを求められた場合のみ
$ . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
$ hash -r
```

`~/.bashrc` にも、以下を追記しておきます。

<a id="code-snippet--=~-.bashrc= への追記内容"></a>
```shell
# Swift
. "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
hash -r
```


## `Hello World` してみる {#hello-world-してみる}

`swift` にパスが通っていることを前提に、以下のコマンドを実行します。

```shell
$ mkdir helloworld
$ cd helloworld
$ swift package init --name HelloWorld --type executable
$ swift run HelloWorld
```

すると、以下のように実行されます。初回はとにかく遅く、Hello Worldだけにも関わらず約5秒の処理時間が掛っていました。

```text
Building for debugging...
[8/8] Linking HelloWorld
Build of product 'HelloWorld' complete! (4.99s)
Hello, world!
```

2回目は以下のようにキャッシュが効いているのか、速くはなってはいますが、それにしても遅いですね。

```text
[1/1] Planning build
Building for debugging...
[1/1] Write swift-version-3F9C5CDD8FC5382D.txt
Build of product 'HelloWorld' complete! (0.20s)
Hello, world!
```


## EmacsでSwiftを使ってみる {#emacsでswiftを使ってみる}

当然、EmacsでもSwiftを使うことができます。私の場合、現時点でSwiftで本格的にプログラムを書く予定はなく、 `org-babel` で少し勉強したいと思っている程度なので、 `ob-swift` と `swift-mode` を導入することにしました。


### PATHを通す {#pathを通す}

以下のような設定を `~/.emacs` に入れることにより、Emacsを起動した際にShellの設定ファイルを読んでパスを通してくれます。事前に、 `M-x package-install` で `exec-path-from-shell` をインストールしておく必要があります。

```emacs-lisp
(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))
```


### `ob-swift` と `swift-mode` をインストールする {#ob-swift-と-swift-mode-をインストールする}

`M-x package-install` から `ob-swift` と `swift-mode` をインストールしておきます。前者は `org-babel` でSwiftを実行するために必要、後者はシンタックスハイライトをするために必要となります。


### `org-babel` でSwiftを実行する {#org-babel-でswiftを実行する}

ここまでの設定を終えていれば、以下のように書くことで `org-babel` でSwiftを実行できます。

```text
#+begin_src swift
let a: Int = 1
print(a)
#+end_src

#+RESULTS:
: 1
```


## まとめ {#まとめ}

実際にiPhone等で動作するアプリケーションを開発するためにはMacbookが必要になりますが、Swiftの基本的な文法は、Linux上でも十分に試すことができますし、 `org-babel` で気軽に試しながら勉強できるというのは大きなメリットになる人もいると思います。

少なくとも、私の場合には `org-babel` が使えるということと、Xcode Playgroundsよりも気軽に試すことができるということはメリットでありますので、しばらくこの環境で勉強しつつ、軌道に乗ってきたらMacbookで実際の開発作業に取り掛かってみようかと思います。
