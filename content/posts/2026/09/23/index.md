---
title: "Emacs 31にしてからの設定見直し"
author: ["sonohen"]
date: 2026-09-23
tags: ["Emacs", "macOS"]
categories: ["Linux"]
draft: false
toc: true
description: "Emacs 31にしてから、色々と警告が出るようになりました。その対応をしたときのメモです。"
---

## 環境 {#環境}

`brew install emacs-app --casks` でインストールした `emacs` を使用している。自分でコンパイルはしていない。

```shell
emacs --version
```

```text
GNU Emacs 31.1
Development version fac653279dcb on HEAD branch; build date 2026-08-24.
Copyright (C) 2026 Free Software Foundation, Inc.
GNU Emacs comes with ABSOLUTELY NO WARRANTY.
You may redistribute copies of GNU Emacs
under the terms of the GNU General Public License.
For more information about these matters, see the file named COPYING.
```

過去の `.emacs` を引っ張り出してきて使おうとしたところ、久し振り過ぎて色々なところで躓いたので、そのときの記録を残すことにした。


## `libgccjit.so` が見つからない {#libgccjit-dot-so-が見つからない}


### 警告内容 {#警告内容}

```plaintext
⛔ Warning (native-compiler): libgccjit.so: error: error invoking gcc driver
```


### 原因 {#原因}

macOSの `gcc` を参照しているため。ネイティブコードにコンパイルするときに `gcc` が `libgccjit` を参照できずにエラーになっている模様。


### 対処 {#対処}

`brew` で `gcc` と `libgccjit` をインストールした。

```shell
% brew install gcc libgccjit
```

その上で `~/.emacs` に以下の記述を追加し `brew` でインストールした `gcc` を呼び出すようにした。

```emacs-lisp
(when (eq system-type 'darwin)
  (setenv "MACOSX_DEPLOYMENT_TARGET" "27.0")
  (let ((brew-prefix "/opt/homebrew"))
    (setenv "PATH" (concat brew-prefix "/bin:" (getenv "PATH")))
    (setq native-comp-compiler-path (concat brew-prefix "/bin/gcc-16"))
    (setenv "LIBRARY_PATH"
            (concat brew-prefix "/lib/gcc/16:"
                    (getenv "LIBRARY_PATH")))))
```


## `Missing 'lexical-binding' cookie` という警告が出力される {#missing-lexical-binding-cookie-という警告が出力される}


### 警告内容 {#警告内容}

```plaintext
⛔ Warning (files): Missing ‘lexical-binding’ cookie in "~/.emacs.d/elpa/ddskk-20260329.1317/skk-cursor.el".
You can add one with ‘M-x elisp-enable-lexical-binding RET’.
See ‘(elisp)Selecting Lisp Dialect’ and ‘(elisp)Converting to Lexical Binding’
for more information.
```


### 原因 {#原因}

実装による。


### 対処 {#対処}

暫定対処となるが、以下の記述を `~/.emacs` に追記する。

```emacs-lisp
(when (require 'warnings nil t)
  (add-to-list 'warning-suppress-log-types '(files missing-lexbind-cookie)))
```
