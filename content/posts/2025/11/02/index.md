+++
title = "SlackwareでThinkPadの液晶の明るさを変える"
author = ["sonohen"]
date = 2025-11-02
tags = ["Slackware", "ThinkPad"]
categories = ["Linux"]
draft = false
toc = true
lead = "Slackware + i3 + ThinkPadな環境において、液晶の明るさを変更するための仕組みを考えました。"
+++

[X.com](https://x.com/sonohenv0/)でもいくつかポストしていますが、先日からSlackwareでi3を使用しています。環境構築作業のなかで最も優先度が低かったのが液晶の明るさを変更するための仕組みであったのですが、今日、ようやく実装しました。

何かツールを入れるのもなぁと思っていたところ、 `/sys/class/backlight/amdgpu_bl0/brightness` を書き換えればよいということがわかり、以下のようなスクリプトを作っておきました。

```shell
#!/bin/sh -e

#
# Usage:
# brightness.sh 1000 (for Brighter)
# brightness.sh -1000 (for Darker)
#

FILE=/sys/class/backlight/amdgpu_bl0/brightness
CURRENT_BRIGHTNESS=`cat $FILE`

TARGET_BRIGHTNESS=$(( $CURRENT_BRIGHTNESS + $1 ))
echo $TARGET_BRIGHTNESS > $FILE
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  <code>~/.local/bin/brightness.sh</code>
</div>

これを、以下のように設定することでキーボードから呼び出すようにしました。

```plaintext
bindsym XF86MonBrightnessUp exec --no-startup-id sudo ~/.local/bin/brightness.sh 4000
bindsym XF86MonBrightnessDown exec --no-startup-id sudo ~/.local/bin/brightness.sh -4000
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  <code>~/.config/i3/config</code>
</div>

私だけしか使っていないシステムなので、 `sudo` は NOPASSWD で実行できるようにしています。

これで、設定を再読み込みすれば、キーボードから液晶の明るさを調整することができるようになります。
