+++
title = "Emacs + DDSKK on kittyな環境で日本語変換がバグる"
author = ["sonohen"]
date = 2025-12-02
tags = ["ArchLinux"]
categories = ["Linux"]
draft = false
toc = true
lead = "tmuxでemacs -nwを実行し、その上でddskkによって日本語入力をすると、ゴミデータもあわせて入力されることがあり、どうしたものかと思っていたところ、kittyとemacsの起動方法を工夫することで、ある程度は軽減できることが分かった。"
+++

## 環境 {#環境}

-   Arch Linux
-   tmux 3.6
-   GNU Emacs 30.2 + DDSKK
-   kitty 0.44.0


## 事象 {#事象}

以下のように入力すると、不正な文字列が入力される。

KiGasuru -&gt; 気gがする


## 解消方法 {#解消方法}

以下のようにすることで、完全な解消は難しいものの軽減はできた。

`~/.config/kitty/kitty.conf`

```cfg
kitty_keyboard_protocol no
```

`~/.local/bin/emacs-noime`

```shell
#!/bin/sh -e

unset GTK_IM_MODULE
unset QT_IM_MODULE
unset XMODIFIERS
unset DefaultImModule
unset GLFW_IM_MODULE

export NO_AT_BRIDGE=1

exec emacs -nw "$@"
```

今後は、 `~/.local/bin/emacs-noime` を `kitty` から呼びだすことで、不正な文字が極力残らないようにして作業を実施できるものと思われる(完全解消するためには、 `emacs -nw` を止めるしかない)。


## その後の検証の結果 {#その後の検証の結果}

結局、上記は効果がなかったとは言えないが、もっとも効果がありそうなのは以下の対策であった。

`~/.config/kitty/kitty.conf`

```cfg
programs.kitty.keybindings = {
  "ctrl+j" = "discard_event";
}
```


## その後の検証の結果(2) {#その後の検証の結果--2}

結局、劇的な効果が見込まれず `emacs -nw` をtmuxの中で動かすことは止めにした。
