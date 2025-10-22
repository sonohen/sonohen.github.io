+++
title = "Slackware -currentでHEIC対応のdigiKamを動かす"
author = ["sonohen"]
date = 2025-10-20
tags = ["Slackware", "digiKam"]
categories = ["Linux"]
draft = true
toc = true
lead = "写真管理のソフトウェアを、macOSの写真アプリから、KDEのdigiKamに移行しました。その際に、HEIC画像を扱うことができなかったので対処をした際のログです。"
+++

## TL;DR {#tl-dr}

Slackware -currentのImageMagick (7.1.2-7)は `--with-heic=yes` でコンパイルされていないため、それを使っているdigiKamでもHEIC/HEIFフォーマットの画像を扱うことができない。同じ理由で、Gwenviewでも扱うことができない。


## そもそもの発端 {#そもそもの発端}

つい最近までDebian GNU/Linuxを使っていたのですが、思うところがありここ数日でSlackware -currentに環境を移行しました。kernel/gcc/emacsを自前でコンパイルし、色々な試行錯誤を繰り返しながら、なんとか必要な作業ができるようになってきたことから、本格的にデータを移行することにしました。

これといった理由は特に無いのですが、趣味の写真をさっさと再開できるようにということで、まずは写真のデータをSlackwareに移行することにしました。


## HEICフォーマットの画像がdigiKamに表示されない {#heicフォーマットの画像がdigikamに表示されない}

HEICフォーマットはiPhone等で使われる形式で、同程度の視覚品質を得るためにはJPEGの50-60%程度のファイルサイズで済むといわれています。つまり、容量に制約のあるスマートフォンや、クラウドサービスの容量を節約したい場合にHEICを使うことが良いのではないかと思われます。私も、iPhoneでHEICが使われるようになってからというもの、iPhoneで撮る写真はすべてHEIC形式になりました。

それらの写真をdigiKamに取り込もうとした時に、サムネイルもプレビューも表示されないので「どうなってんだ？」と思い調査したところ、まず判ったのは `libheif` がシステムにインストールされていないことでした。


## `libheif` をインストールする {#libheif-をインストールする}

`libheif` は `libaom` と `libde265` に依存している。まずはそれらをシステムにインストールする必要があるので、準備する。 `libaom` は[darkskygit / libaom](https://github.com/darkskygit/libaom)から入手することができる。また `libde265` は[structurag / libde265](https://github.com/strukturag/libde265)から入手できるので、それぞれREADMEを参考にコンパイルしてパッケージを作り `installpkg` でインストールしておく。

次に `libheif` をインストールする。 `libheif` は[structurag / libheif](https://github.com/strukturag/libheif)から入手できるので、こちらもREADMEを参考にコンパイルしてパッケージを作り `installpkg` でインストールしておく。途中 `/usr/lib64/libaom.a` が見付からないというエラーが出るので `ln -s /usr/lib64/libaom.a /usr/local/lib64/libaom.a` としてsymlinkを張っておく。

ここまで実施してdigiKamを起動しても状況は変わらなかった。なぜだと考え、調べているうちに、どうやらdigiKamはバックエンドにImageMagickを使っていそうだということがわかり、では、ImageMagickでHEIC/HEIFは有効になっているのだろうかと調べたところ有効になっていなかったのであった。

```shell
$ magick -list format | grep HEIC    # 結果は何も表示されなかった => 無効
$ magick -list format | grep HEIF    # 結果は何も表示されなかった => 無効
```


## ImageMagickを `--with-heic=yes` つきでインストールする {#imagemagickを-with-heic-yes-つきでインストールする}

ImageMagicは、[currentのソースコード](https://mirrors.slackware.com/slackware/slackware-current/source/l/imagemagick/)をもとにコンパイルする。 `imagemagic.SlackBuild` の中に記載されている `./configure` に対し `--with-heic=yes` を指定したうえでパッケージを作成し、インストールする。

ここまで実施した上でdigiKamを開くと、HEICフォーマットの画像が表示されるようになっているはずである。


## DolphinとGwenviewでもHEICを扱いたい場合は、KImageFormatsをHEICサポートつきでコンパイルし、インストールする必要がある {#dolphinとgwenviewでもheicを扱いたい場合は-kimageformatsをheicサポートつきでコンパイルし-インストールする必要がある}

ここまで実施しても、まだDolphinやGwenviewでHEICを表示することはできない。それらでHEICを扱うためには、KImageFormatsをHEICサポートつきでコンパイルし、インストールする必要がある。 `cmake` の引数に `-DKIMAGEFORMATS_HEIF=on` を指定してコンパイルし、パッケージを作成、インストールする。

こうして無事、私の写真ライブラリはSlackwareマシンに移行されたのでした。


## まとめ {#まとめ}

こうしてまとめてしまうと何てことのない作業なのですが、実際にはログを見たり、インターネットで調査したり、横道に逸れたりしながら調査して、結構時間を喰ったように思います。が、まずはHEICがきちんと取り扱える環境になってめでたし、めでたし。

こういう調査は知識を身に付けるよい機会であるので、きちんと記録を取りながら対応し、知識を整理していきたい。今回は、作業ログをChangeLogのフォーマットで記録しておいたので、それを参考にしながらこの記事を書きました。
