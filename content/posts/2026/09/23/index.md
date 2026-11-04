---
title: "Emacs 31の設定中に対処したエラーと警告"
author: ["sonohen"]
date: 2026-09-23
lastmod: 2026-11-04T20:24:15+09:00
tags: ["Emacs", "macOS"]
categories: ["Linux"]
draft: false
toc: true
description: "macOSでEmacs 31を導入した際に発生した、libgccjitのコンパイルエラーとlexical-bindingの警告について、原因と対処方法を実際の設定例とともに解説します。"
---

## 環境 {#環境}

-   ****マシン****: MacBook M3 Air
-   ****OS****: MacOS Tahoe

Emacsは、 `brew install emacs-app --casks` でインストールしたものを使用している。

```sh
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

Emacsのセットアップをしている際に、それ以前のEmacsで使用できていた `.emacs` が急にエラーを出力し始めた。そのため、対処の記録を残すことにした。


## Native CompilationでGCCのコンパイル・リンク処理に失敗する（ `libgccjit.so: error: error invoking gcc driver` ） {#native-compilationでgccのコンパイル-リンク処理に失敗する-libgccjit-dot-so-error-error-invoking-gcc-driver}


### 警告の内容 {#警告の内容}

> ⛔ Warning (native-compiler): libgccjit.so: error: error invoking gcc driver


### 原因 {#原因}

EmacsのNative Compilationに必要な `libgccjit` が導入されていない、またはGCCのコンパイル・リンクに必要なライブラリや実行ファイルを参照できない場合に発生する。特にmacOSでは、Homebrewで導入したGCCのライブラリパスが適切に設定されていないことが原因となる場合がある。


#### 参考 {#参考}

-   [18 Compilation of Lisp to Native Code](https://www.gnu.org/software/emacs/manual/html_node/elisp/Native-Compilation.html)
-   [Known Problems with GNU Emacs : Native Compilation on macOS](https://fossies.org/linux/emacs/etc/PROBLEMS)


### 対処 {#対処}

`brew` で `libgccjit` をインストールし、 `LIBRARY_PATH` を通す。

```sh
brew install libgccjit
```

その上で、 `~/.emacs` に以下の記述を追加する。

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


## レキシカルバインディングが有効になっていない (`Missing 'lexical-binding' cookie`) という警告が出力される {#レキシカルバインディングが有効になっていない--missing-lexical-binding-cookie--という警告が出力される}


### 警告内容 {#警告内容}

```text
⛔ Warning (files): Missing ‘lexical-binding’ cookie in "~/.emacs.d/elpa/ddskk-20260329.1317/skk-cursor.el".
You can add one with ‘M-x elisp-enable-lexical-binding RET’.
See ‘(elisp)Selecting Lisp Dialect’ and ‘(elisp)Converting to Lexical Binding’
for more information.
```


### 原因 {#原因}

Emacsは、将来的に `lexical-binding` (従来のダイナミックバインディング( `dynamic-binding` )とは異なる変数束縛の方式)がデフォルトで有効になることに備え、Emacs 31では `lexical-binding` に対する警告が強化された。
(ただし、Emacs 31では、警告がでるものの、引き続き `dynamic-binding` がデフォルトになっている)。

今回の警告は、 `ddskk` に含まれる `skk-cursor.el` に当該宣言が無いことによって発生している。


#### 参考 {#参考}

-   [[emacs-devel] missing lexical-binding cookie warning when loading .el files](https://lists.gnu.org/archive/html/emacs-devel/2024-05/msg00250.html)
-   [GNU Emacs NEWS : Lexical binding](https://fossies.org/linux/misc/emacs-31.1.tar.xz/emacs-31.1/etc/NEWS)


### 対処 {#対処}

`skk-cursor.el` など、本警告が表示されるEmacs Lispファイルに `lexical-binding` の宣言を加えることも考えたが、無闇に追加するとどのような影響が生じるか分からないことから、当該警告を `*Warnings*` バッファに出力しないように、抑止する設定を暫定的に加えた。

以下の記述を `~/.emacs` に追記する。

```emacs-lisp
(when (require 'warnings nil t)
  (add-to-list 'warning-suppress-log-types '(files missing-lexbind-cookie)))
```

いろいろと出るものだなぁ...。
