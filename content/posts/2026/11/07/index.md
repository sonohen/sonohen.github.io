---
title: "NixOSで、Nixpkg(26.05)が想定する ripgrep の場所が古く、 ビルド (postPatch 処理) に失敗する"
author: ["sonohen"]
date: 2026-11-07
lastmod: 2026-11-07T22:59:56+09:00
tags: ["NixOS", "Visual-Studio-Code"]
categories: ["Linux"]
draft: false
toc: true
description: "NixOS 26.05を更新しようとしたところ、VSCodeのビルド処理に失敗した。ripgrepのパスについて、postPatch処理で想定しているパスと、実際に配置されているパスとが相違していたことが原因である。今回は、暫定処理としてhome-vscode.nixにパスを書き換える記述を追加することで回避した。"
---

## 環境 {#環境}

-   ****OS****: NixOS 26.05
-   ****マシン****: ThinkPad E14 Gen 3 (24GB RAM)
-   ****VSCode****: 1.144.0


## 事象 {#事象}

NixOSを再構築( `sudo nixos-rebuild switch --flake ./nixos#thinkpad` )したところ、 `patchPhase` にてripgrep (`rg`)の削除に失敗し、再構築できなかった。

```text
error: Cannot build '/nix/store/19qb09s88pznbvg93wj4gi40gfa74h6y-vscode-1.144.0.drv'.
       Reason: builder failed with exit code 1.
       Output paths:
         /nix/store/3q7avpv0jk7fbnb70c3pv307rnzzw6zn-vscode-1.144.0
       Last 6 log lines:
       > Running phase: unpackPhase
       > unpacking source archive /nix/store/nddxnzrjcnlyx5d414506qnq0da0xqb9-VSCode_1.144.0_linux-x64.tar.gz
       > source root is VSCode-linux-x64
       > setting SOURCE_DATE_EPOCH to timestamp 1793133762 of file "VSCode-linux-x64/bin/copilot-shim/copilot"
       > Running phase: patchPhase
       > rm: cannot remove 'resources/app/node_modules/@vscode/ripgrep/bin/rg': No such file or directory
       For full logs, run:
         nix log /nix/store/19qb09s88pznbvg93wj4gi40gfa74h6y-vscode-1.144.0.drv
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  エラーメッセージの抜粋
</div>

`nix log /nix/store/19qb09s88pznbvg93wj4gi40gfa74h6y-vscode-1.144.0.drv` の実行結果は次の通りである。

```text
Running phase: unpackPhase
@nix { "action": "setPhase", "phase": "unpackPhase" }
unpacking source archive /nix/store/nddxnzrjcnlyx5d414506qnq0da0xqb9-VSCode_1.144.0_linux-x64.tar.gz
source root is VSCode-linux-x64
setting SOURCE_DATE_EPOCH to timestamp 1793133762 of file "VSCode-linux-x64/bin/copilot-shim/copilot"
Running phase: patchPhase
@nix { "action": "setPhase", "phase": "patchPhase" }
rm: cannot remove 'resources/app/node_modules/@vscode/ripgrep/bin/rg': No such file or directory
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  <code>nix log /nix/store/19qb09s88pznbvg93wj4gi40gfa74h6y-vscode-1.144.0.drv</code> の実行結果
</div>


## 原因 {#原因}

`pkgs/applications/editors/vscode/generic.nix` の `postPatch` 処理で指定されているLinux向けのripgrep (`rg`)のパス ( `@vscode/ripgrep/bin/rg` )が、
VS Code 1.144.0での実際の配置先のパス ( `@vscode/ripgrep-universal/bin/linux-x64/rg` ) と相違している。そのため、前者のパスを前提として実行される `rm` の処理が失敗することが原因である。

```nix
let
  vscodeRipgrep =
    if stdenv.hostPlatform.isDarwin then
      if lib.versionAtLeast vscodeVersion "1.94.0" then
        "Contents/Resources/app/node_modules/@vscode/ripgrep/bin/rg"
      else
        "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep/bin/rg"
    else
      "resources/app/node_modules/@vscode/ripgrep/bin/rg";
in
if !useVSCodeRipgrep then
  ''
    rm ${vscodeRipgrep}
    ln -s ${ripgrep}/bin/rg ${vscodeRipgrep}
  ''
else
  ''
    chmod +x ${vscodeRipgrep}
  ''
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1:</span>
  <code>pkgs/applications/editors/vscode/generic.nix</code> の <code>postPatch</code> 処理で指定されているLinux向けのripgrep (<code>rg</code>)のパス(該当箇所抜粋)
</div>

ソースコード: [/pkgs/applications/editors/vscode/generic.nix#L410付近](https://github.com/NixOS/nixpkgs/blob/c56a87d8e41ce69bd2af57eb35dcc117a9dfca33/pkgs/applications/editors/vscode/generic.nix#L410)

```js
export function binPathFor({ os, arch }) {
    const binaryName = os === 'win32' ? 'rg.exe' : 'rg';
    return path.join(_packageRoot, 'bin', `${os}-${arch}`, binaryName);
}
```
<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2:</span>
  VS Code 1.144.0で ripgrep ( <code>rg</code> )が実際に配置されるパス
</div>

`${os}` は `linux` 、 `${arch}` は `x64` 、 `binaryName` は `rg` となる。そのため、パッケージのルートディレクトリを基準とした配置先は `bin/linux-x64/rg` であり、Nixのビルド時に基準とするパスは `/resources/app/node_modules/@vscode/ripgrep-universal/bin/linux-x64/rg` となる。

ソースコード: [@vscode/ripgrep-universal@1.18.0/lib/index.js](https://unpkg.com/@vscode/ripgrep-universal@1.18.0/lib/index.js)


## 対処 {#対処}

`home-vscode.nix` に以下の記述を追加し、再度、NixOSの再構築を実施した。

```nix
package = (pkgs.vscode.override {
  commandLineArgs = "--locale=ja";
}).overrideAttrs (old: {
  # Work around the old ripgrep path in nixos-26.05 for VS Code >= 1.122.
  postPatch = pkgs.lib.replaceStrings
    [ "resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
    [ "resources/app/node_modules/@vscode/ripgrep-universal/bin/linux-x64/rg" ]
    old.postPatch;
});
```


### 注記 {#注記}

-   本対処は、 Linux x86_64向けとなる。
-   Nixpkgs側で修正されたあとは、この `overrideAttrs` を削除する。
