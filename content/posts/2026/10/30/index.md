---
title: "Cachixを使用する"
author: ["sonohen"]
date: 2026-10-30
tags: ["NixOS"]
categories: ["Linux"]
draft: false
toc: true
description: "nixのバイナリキャッシュを保管するための外部ストレージであるCachixを導入した。私の環境の場合、emacs-unstable-pgtkやopenlogiは更新の都度、ビルドがかかる。それが日常作業に影響するためGitHub Actionsと組合せて自動ビルドするようにした。"
---

## 課題と目的 {#課題と目的}

私の環境では `emacs-unstable-pgtk` と `openlogi` は、更新が入る度にビルドが走る。それはそれで構わないのだが、一方で日常作業をしている裏でリソースを取られるのも少し違う気がした。

そこで、以下のような構成を実装した。

```text
GitHub(master) <--[checkout]-- GitHub Actions(毎週金曜日4:30起動 / Ubuntu) --[push]--> Cachix
    ^                                                                                     |
    `--------[git pull]-------- ThinkPad E14 Gen 3 <--------[nixos-rebuild switch]--------/
```

この構成により、最も時間を要している `emacs-unstable-pgtk` と `openlogi` はGitHub Hosted Runnerでビルドされるので、
ThinkPadで `nixos-rebuild switch --flake ./nixos#thinkpad` を実行したときに、ローカルビルド時間を大幅に短縮できるというのが目論見である。
(ローカルビルドを完全に無くすとは言っていない)


## 日常の運用 {#日常の運用}

以下の通りになる。

-   毎週金曜日4:30 GitHub Actionsが起動する。
    -   `flake.lock` の更新
    -   `emacs-unstable-pgtk` のビルドとCachixへの転送
    -   `openlogi` のビルドとCachixへの転送
    -   `flake.lock` のコミットとリポジトリへのプッシュ
-   毎週土曜日に、ThinkPadで `git pull`, `sudo nixos-rebuild switch --flake ./nixos#thinkpad` を実行。
    -   このタイミングで、 `emacs-unstable-pgtk` や `openlogi` はビルドされず、Cachixからダウンロードされる。


## 実装 {#実装}


### `configuration.nix` {#configuration-dot-nix}

`cachix.org` からnixバイナリキャッシュを取得するように設定する。

```nix
extra-substituters = [
  "https://<キャッシュ名>.cachix.org"
];

extra-trusted-public-keys = [
  "<キャッシュ名>.cachix.org-1:<公開鍵>"
];
```


### `flake.nix` {#flake-dot-nix}

ストアパスが一致するように設定する。

```nix
...
outputs = { self, nixpkgs, home-manager, nixvim, openlogi, beancount-mode, emacs-overlay, ... }: {
  packages.x86_64-linux = {
    emacs = self.nixosConfigurations.thinkpad.pkgs.emacs-unstable-pgtk;
    openlogi = self.nixosConfigurations.thinkpad.config.programs.openlogi.package;
  };

  nixosConfigurations = {
    thinkpad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./common/configuration.nix
        ./thinkpad/configuration.nix
        home-manager.nixosModules.home-manager
        openlogi.nixosModules.default

        {
          nixpkgs.overlays = [
            emacs-overlay.overlays.emacs
          ];
        }

        {
          home-manager.sharedModules = [
            nixvim.homeModules.nixvim
          ];

          home-manager.extraSpecialArgs = {
            inherit beancount-mode;
          };
        }

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sonohen = import ./common/home.nix;
        }
      ];
    };
```


### `.github/workflows/nixos-parts-build.yml` {#dot-github-workflows-nixos-parts-build-dot-yml}

これが毎週金曜日4:30に起動する。

```yml
name: Update and Build NixOS Packages

on:
  schedule:
    - cron: "30 4 * * 5"
      timezone: "Asia/Tokyo"
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: nixos-update-build
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-24.04
    timeout-minutes: 360

    steps:
      - name: Checkout
        uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          ref: master
          persist-credentials: false

      - name: Install Nix
        uses: cachix/install-nix-action@8aa03977d8d733052d78f4e008a241fd1dbf36b3 # v31.10.6
        with:
          extra_nix_config: |
            max-jobs = 1
            cores = 2

      - name: Setup Cachix
        uses: cachix/cachix-action@38b082610b782e7e93e209c35fd730d399dee866 # v17
        with:
          name: sonohen-cachix
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Update flake.lock
        working-directory: nixos
        run: nix flake update

      - name: Build Emacs
        run: |
          nix build ./nixos#emacs \
            --no-link \
            --print-build-logs

      - name: Build OpenLogi
        run: |
          nix build ./nixos#openlogi \
            --no-link \
            --print-build-logs

      - name: Commit and push flake.lock
        run: |
          if git diff --quiet -- nixos/flake.lock; then
            echo "No updates"
            exit 0
          fi

          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

          git add nixos/flake.lock
          git commit -m "chore(nix): update flake.lock"

          git -c http.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 -w0)" \
            push origin HEAD:master
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```


## 結果 {#結果}


### ビルドの所要時間と容量 {#ビルドの所要時間と容量}

-   `emacs-unstable-pgtk` のビルド時間は、2026-10-30現在の `emacs-unstable-pgtk-31.1` で35分35秒。
-   `openlogi` のビルド時間は、2026-10-30現在の `0.8.19` で27分20秒。
-   Cachixの利用容量は642.6 MiB。
    -   無料で利用できる容量が5.0GiBなので、5~6世代持たせておけばよいかな。


## 今後の課題 {#今後の課題}

neovimをこの構成のなかに入れておくかどうするかを検討する必要がある。次の更新のタイミングで検討することにしたい。
