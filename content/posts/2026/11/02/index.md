---
title: "CodexをDocker Sandboxに隔離して安全に動かすためのチュートリアル"
author: ["sonohen"]
date: 2026-11-02
tags: ["Codex", "Docker", "NixOS", "Generative-AI"]
categories: ["Programming"]
draft: false
toc: true
description: "Codexを隔離せずに動作させるのに不安を感じ、これまでは自分で構築したDockerコンテナで動作させていた。しかし、2026年2月にDocker SandboxというAIエージェントを隔離させるためのツールが公表され、気軽に隔離できるようになった。今回は、NixOSでDocker Sandboxを動作させ、外部との通信を許可するところまで検証した。"
---

## 課題感 {#課題感}

AIエージェントは、人間やコンピュータから必要な情報を集め、それらと推論に基づいて自律的に計画を立てて、タスクを消化する。これは非常に便利なことであり、日々の仕事や作業の効率が上がっている印象がある。

その一方で、昨今ニュースを賑わせたように、AIエージェントが暴走したときのことを考えたい。本来は見て欲しくないコンピュータ上の情報や、アクセスしてほしくないサイトにアクセスし、その結果として情報漏洩に繋がるケースもありえる。よって、「AIエージェントをどう動かすか」と同じかそれ以上に、「AIエージェントをどこで動かすか」も重要になっている。

さて、「どこで動かすか」は、概ね以下のような考え方があるのではないかと思う。

1.  いつも使用しているコンピュータにAIエージェントをインストールして動作させる。
2.  何も入っていない専用のコンピュータで動作させる。
3.  仮想マシン上で動作させる。
4.  Dockerコンテナ上で動作させる。

1.は、もはや論外と言ってもよいかもしれない。普段遣いの環境で、広い権限を与えて動かすことには、不安がある。
2.は、流行りの方法かもしれない。古いMacBook等を初期化して、その中でAIエージェントを動作させる。
3.は、ホストとAIエージェントを(ほぼ)完全に分離できる一方で、OSの維持が非常に面倒である。
4.は、3.よりは簡易であるものの、AIエージェントが本当に暴走した際にはホスト側のカーネルに触ることができる可能性があるし、3.と同じようにコンテナのメンテナンスの手間がかかる。

今回紹介するDocker Sandboxは、3.と4.の合わせ技のような技術である。つまり、仮想マシンによる隔離と、コンテナのような扱いやすさを組合せ、AIエージェント専用の仮想マシンを手に入れることができる。
(無論、突き詰めればネットワークの分離、共有するファイル、外部との通信のあり方等を検討する必要は残る)


## 検証目的 {#検証目的}

以下の検証を目的とする。ちなみに[]内のキーワードは、[Follow an authenticated request](https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)の箱を指しており、今回の検証でDocker Sandbox全体の概要を掴みたいと思う。

1.  NixOSで、最新のDocker Sandboxを動作させる方法を確立する [SANDBOX MICROVM]。
2.  Codexの認証は、APIキーではなくOAuth認証で行い、既存のサブスクリプションを変更せずとも使用できることを確認する [Model Provider]。
3.  秘密情報をSandbox内部に保存することなく、認証が必要な外部サービスを利用する方法を確認する。そのため、今回はGitHubリポジトリへのアクセスを検証する [Host-side proxy/Credential store]。
4.  Docker Sandboxが予め許可しているドメインに加え、自身が承認したドメインへの通信を許可する方法を確認する [Network Policy]。


## 検証環境 {#検証環境}

-   ****マシン****: ThinkPad E14 Gen 3 (AMD/ 24GB RAM)
-   ****OS****: NixOS 26.05
-   ****sbx (Docker Sandbox)****: 0.50.1


## 検証 {#検証}


### NixOSで、最新のDocker Sandboxを動作させる方法を確立する [SANDBOX MICROVM] {#nixosで-最新のdocker-sandboxを動作させる方法を確立する-sandbox-microvm}


#### Docker Sandboxをインストールする {#docker-sandboxをインストールする}

2026年11月2日現在、最新の[Docker Sandbox](https://github.com/docker/sbx-releases)は `0.50.1` である。一方で、nixpkg(26.05)で配信されているDocker Sandboxは `0.34.0` であり、約4ヶ月前のものである。

```sh
nix search nixpkgs sbx
```

```text
* legacyPackages.x86_64-linux.docker-sbx (0.34.0)
  Safe environments for agents
```

そこで、Docker Sandboxは、NixOSをサポートしてはいないものの、Linux (amd64) 向けのバイナリが公開されているので、それを利用する。
`configuration.nix` に以下を追記する(必要な箇所のみ抜粋)。

```nix
let
  docker-sbx-latest = pkgs.docker-sbx.overrideAttrs (old: rec {
    version = "0.50.1";
    src = pkgs.fetchurl {
      url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux-amd64.tar.gz";
      hash = "sha256-es2HtXlRGbJO+6u3ZBtxRpBoPwRJJMcQrJtLq+dM1UY=";
    };
  });
in
{
  # Allow unfree software
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    docker-sbx-latest
  ];

  users.users."<user_name>" = {
    extraGroups = [ "kvm" ];
  };
}
```

NixOSの再構築を行い、ログオフ後にログインし直して変更を反映する。以下のコマンドを実行してバージョン情報が返ってくれば成功である。

```sh
sbx version
```

```text
sbx version v0.50.1 ddb0268d7124b9cf98955d0b08ffd71a0dfcebe4
```


#### 動作確認をする {#動作確認をする}

基本的には、以下のマニュアルに沿って確認していく。

-   [Install Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install/)
-   [Codex](https://docs.docker.com/ai/sandboxes/agents/codex/)

まずはKVMの状態を確認する。

```sh
lsmod | grep kvm
```

```text
kvm_amd               249856  0
ccp                   192512  1 kvm_amd
kvm                  1421312  1 kvm_amd
irqbypass              16384  1 kvm
```

`kvm` グループに所属しているかを確認する。

```sh
cat /etc/group | grep sonohen
```

```text
wheel:x:1:sonohen
networkmanager:x:57:nm-openvpn,sonohen
scanner:x:59:sonohen
kvm:x:302:sonohen
```

Docker Sandboxを動作させるには、Docker Accountが必須である。そのため、ここでdockerにログインする。

```sh
sbx login
```


### Codexの認証は、APIキーではなくOAuth認証で行い、既存のサブスクリプションを変更せずとも使用できることを確認する [Model Provider] {#codexの認証は-apiキーではなくoauth認証で行い-既存のサブスクリプションを変更せずとも使用できることを確認する-model-provider}

次に、Codexの認証を行う。今回はChatGPTの3,000円プランで進めるためOAuthで認証する。

```sh
sbx secret set openai --oauth
```

とりあえず `~/sbx-codex-work` を作成し、その中でCodexを起動 (`sbx run codex`) してみる。ここで重要なのは、以下の2点であるように思う。

-   Sandbox内からどのサイトにアクセスできるかは、ユーザが制御できること。ここでは「Balanced(一般的な開発用サイト(github.com等)は許可されており、それ以外はユーザによる明示的な許可が必要)」を選択した。
-   ホスト側にある `~/.codex/skills/` は、Sandbox内では使用できないこと。ホスト側の設定やファイルをSandboxに持っていくことはなく、隔離されたCodexからはプロジェクトのフォルダ(起動フォルダと共有設定したリソース)しか参照できない([Codex | Docker Docs](https://docs.docker.com/ai/sandboxes/agents/codex/#configuration))。そのため、 `~/.codex/skills/` はSandbox内で使用することはできず、プロジェクトに保存したものを使うか、ホストの `~/.local/state/sandboxes/sandboxes/agent-skills` に格納されたものを使う。

<!--listend-->

```text
  ✓ started daemon (2s)

Choose the network policy for sandboxes
  1. Open   all network traffic allowed, no restrictions
  2. Balanced   default deny, with common dev sites allowed
  3. Locked Down   all network traffic blocked unless you allow it
Choice [1-3, default 2]: 2

Set network policy Balanced
  try: sbx policy reset
   or: sbx policy allow network HOST
   or: sbx policy deny network HOST
   or: sbx policy rm network HOST

SANDBOX
  Name:       codex-sbx-codex-work
  Agent:      codex
  Workspace:  ~/sbx-codex-work (rw)
  Skills:     0 entries · linked, read-only
    Source:   ~/.local/state/sandboxes/sandboxes/agent-skills
    Target:   /home/agent/.agents/skills
  Image:      docker/sandbox-templates:codex-docker
  CPU:        12
  Memory:     11.2 GiB

IMAGE
  ✓ image — ready
  ✓ OpenAI — using stored OAuth credentials

  ✓ Created sandbox codex-sbx-codex-work

  ○ codex — starting in sandbox codex-sbx-codex-work…
      workspace /home/sonohen/sbx-codex-work
```

その後、見慣れたCodexのTUI画面が表示される。

```text
>_ OpenAI Codex (v0.165.0)
   /home/sonohen/sbx-codex-work
permissions: YOLO mode
```

`YOLO mode` と表示されているとおり、 `codex` は、特に指定しない限り `--dangerously-bypass-approvals-and-sandbox` で起動している。

ここまで終わったら、 `/quit` と入力し、 `codex` を終了(Sandboxから抜ける)しておく。


### 秘密情報をSandbox内部に保存することなく、認証が必要な外部サービスを利用する方法を確認する [Host-side proxy/Credential Provider] {#秘密情報をsandbox内部に保存することなく-認証が必要な外部サービスを利用する方法を確認する-host-side-proxy-credential-provider}


#### おおまかな流れ {#おおまかな流れ}

まず、どのように認証済リクエストが流れていくかは、[Follow an authenticated request](https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)に記載がある。これによると、秘密情報はSandbox内部ではなくホスト側に保持していることから、Sandbox内の `codex` からは参照できない仕組みになっている。厳密に言えば、秘密情報がSandbox内に保持される場合もあるのだが、それはあくまでもダミー値 (Sentinel) である。実際の値はホスト側の「Credential store」に格納され、「Host-side proxy」によって書き換えられる。今回は、Credential storeにGNOME Keyringが使用されている。


#### Docker Sandbox内からGitHubにアクセスしてみる {#docker-sandbox内からgithubにアクセスしてみる}

[Built-in services](https://docs.docker.com/ai/sandboxes/configuration/credentials/#built-in-services)によれば、 `sbx secret set github --command 'gh auth token'` を実行することにより、GitHub CLIの認証情報をCredential storeに格納し、Docker Sandbox内から使用できるようにしてくれる。まずは `gh` (GitHubのCLIクライアント)を使えるようにしなければならないのだが、私は普段、これを使用していない。検証のためにインストールするのもあれなので `nix-shell` で対応する。以下のコマンドをホスト側で実行する。

```sh
nix run nixpkgs#gh auth login
sbx secret set github --command 'nix run nixpkgs#gh auth token'
```

これが終わったら以下のようなプロンプトを Codex に渡して設定を確認する。

> \`sbx secret set github\` しました。この設定が正しく行われていることを確認したいので、ためしにリポジトリの一覧を取得してください。

ただしく設定されていれば、リポジトリの一覧が取得できる。

> GitHub API への認証に成功しました。ユーザー sonohen として、非公開リポジトリを含む 44 件を取得できています。取得した一覧の一部（更新順）です。
>
> | リポジトリ                | 公開設定 |
> |----------------------|------|
> | sonohen/sonohen.github.io | 公開 |
>
> (以下、省略)

今回の場合、 `sbx secret set github` した結果は、GNOME Keyringに保管される([Where secrets are stored](https://docs.docker.com/ai/sandboxes/configuration/credentials/#where-secrets-are-stored))。以下のコマンドで確認した。 `9` という数字は環境に依存するので、適宜読み替えていただきたい。

```sh
busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login/9 org.freedesktop.Secret.Item Label
```

```text
s "com.docker.sandboxes:sandboxes:docker/sandbox/credentials/_/github"
```

```sh
busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login/9 org.freedesktop.Secret.Item Attributes
```

```text
a{ss} 4 "id" "docker/sandbox/credentials/_/github" "service:group" "com.docker.sandboxes" "service:name" "sandboxes" "xdg:schema" "org.freedesktop.Secret.Generic"
```

ちなみにこの階層構造は以下のコマンドで確認できる。

```sh
busctl --user tree org.freedesktop.secrets
```

```text
└─ /org
  ├─ /org/freedesktop
  │ ├─ /org/freedesktop/portal
  │ │ └─ /org/freedesktop/portal/desktop
  │ │   └─ /org/freedesktop/portal/desktop/request
  │ │     └─ /org/freedesktop/portal/desktop/request/1_48
  │ │       └─ /org/freedesktop/portal/desktop/request/1_48/5B78FD36644BB6B05513F85778626166
  │ └─ /org/freedesktop/secrets
  │   └─ /org/freedesktop/secrets/collection
  │     ├─ /org/freedesktop/secrets/collection/login
  │     │ ├─ /org/freedesktop/secrets/collection/login/1
  │     │ ├─ /org/freedesktop/secrets/collection/login/2
  │     │ ├─ /org/freedesktop/secrets/collection/login/3
  │     │ ├─ /org/freedesktop/secrets/collection/login/4
  │     │ ├─ /org/freedesktop/secrets/collection/login/5
  │     │ ├─ /org/freedesktop/secrets/collection/login/6
  │     │ ├─ /org/freedesktop/secrets/collection/login/7
  │     │ ├─ /org/freedesktop/secrets/collection/login/8
  │     │ └─ /org/freedesktop/secrets/collection/login/9
  │     └─ /org/freedesktop/secrets/collection/session
  └─ /org/gnome
    └─ /org/gnome/keyring
      └─ /org/gnome/keyring/daemon
```

ちなみに、 `gh auth login` した際の認証情報は、今回の環境では `/org/freedesktop/secrets/collection/login/8` に対応していた。


#### (参考) Sandbox内のCodexに、認証情報が読み込めるか確認した結果 {#参考--sandbox内のcodexに-認証情報が読み込めるか確認した結果}

結論としては、認証情報は読み込めるが、それはダミーの認証情報であり、それを使ってGitHubを操作することはできないというものである。あくまで、実際の認証情報はホスト側のHost-side proxy、Credential Providerによって提供されるというものである。

プロンプトは以下を指定した。

```text
Sandbox内のCodexから認証情報にアクセスできる？
```

回答は次の通り。

```text
調査できました。Sandbox 内で読めたのはダミーの認証情報で、実際の GitHub トークンはホスト側のプロキシが付与する仕組みです。
値を表示せず、GET /user で比較した結果です。

| 通信方法                                  | 結果                   |
|-------------------------------------------+------------------------|
| GH_TOKEN を使い、プロキシ経由             | sonohen として認証成功 |
| 無効なトークンで、プロキシ経由            | 同じく認証成功         |
| トークンなしで、プロキシ経由              | 同じく認証成功         |
| GH_TOKEN を使い、明示プロキシを使わず通信 | 401（認証失敗）        |

Sandbox には起動時から GH_TOKEN が渡されており、gh auth token はその値を返していました。しかし、その値自体では GitHub に認証できません。HTTPS プロキシは gateway.docker.internal:3128 に設定されています。
Docker の公式説明 (https://docs.docker.com/ai/sandboxes/architecture/#follow-an-authenticated-request)にも、Sandbox 内には代替値（sentinel）を渡し、ホスト側のプロキシが実際の認証情報に置き換えると記載されています。
つまり、今回の構成は実トークンの窃取を防ぐ効果があります。一方、Codex はプロキシ経由で GitHub の権限を利用できるため、プロンプトインジェクションによる操作の悪用には、トークンの権限制限も必要です。
なお、ホスト側の保存先が GNOME Keyring かどうかは、今回の Sandbox 内の調査では確認していません。
```


### Docker Sandboxが予め許可しているドメインに加え、自身が承認したドメインへの通信を許可する方法を確認する [Network Policy] {#docker-sandboxが予め許可しているドメインに加え-自身が承認したドメインへの通信を許可する方法を確認する-network-policy}

Network Policyは、Docker Sandbox全体に共通する設定と、個別のSandboxに適用される設定の2つがあり、冒頭で設定したNetwork Policyである `Balanced` は、Docker Sandbox全体に共通する設定である。そのため、どのSandboxからも、基本的な開発用サイトにはアクセスできるが、それ以外にアクセスするためにはユーザの明示的な許可が必要である。例えば、以下のようにBBCから最新のニュースを取得しようとすると失敗する。

```text
BBCから最新のニュースを5件取得して。
```

> BBCのニュース見出しを最新順で確認します。取得できた記事にはリンクも付けます。
> ...
> BBCへのアクセスも403 Forbiddenで拒否され、最新記事を取得できませんでした。記事の見出しやリンクを確認できていないため、5件を正確にお伝えすることはできません。

これは、Network Policyにより、BBCへのアクセスが遮断されていることを示している。実際に拒否されているかどうかを調べるには、以下のコマンドをホスト側で実行して確認する。

```sh
sbx policy approval ls
```

```text
APPROVAL                                              SANDBOX                   TITLE                                        DETAIL                                                                                                                                                 OPTIONS
                                                                            allow (Allow), dismiss (Dismiss)
network:J53qFzroB8iTgn-IwcfkCwRBPAXTuz_xNYBWKjxDMrE   codex-sbx-codex-work      feeds.bbci.co.uk:443                         Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
network:Gm11oDu3PS3dYXROHzzUYqsYsGcWcaNz8hHId1XY5I4   codex-sbx-codex-work      www.bbc.com:443                              Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
network:-lxOnQVAz9ZKBsk6jZKid-TEzjcujY92b6vRalW0PdI   codex-sbx-codex-work      bbc.com:443                                  Protocol: TCP Resource type: domain no matching allow rule (default deny)                                                                              allow (Allow), dismiss (Dismiss)
```

この結果から、 `bbc.com`, `feeds.bbci.co.uk` へのアクセスは許可されていないことが分かる。ここで、3つのドメインについて許可するには、以下のコマンドを実行する。 `network:~~~` には、実際の環境で `sbx policy approval ls` して得られたAPPROVAL IDを指定する。

```sh
sbx policy approval respond network:J53qFzroB8iTgn-IwcfkCwRBPAXTuz_xNYBWKjxDMrE --option allow # feeds.bbci.co.uk:443
sbx policy approval respond network:Gm11oDu3PS3dYXROHzzUYqsYsGcWcaNz8hHId1XY5I4 --option allow # www.bbc.com:443
sbx policy approval respond network:-lxOnQVAz9ZKBsk6jZKid-TEzjcujY92b6vRalW0PdI --option allow # bbc.com:443
```

```text
Recorded answer Allow
Recorded answer Allow
Recorded answer Allow
```

この状態で、もう一度BBCの最新ニュースを取得させる。(プロンプトは先と同じ)
すると、以下の結果が得られる。

> BBCニュースのRSSフィードで確認した最新5件です（公開時刻はUTC、2026年11月3日）。
>
> 1.  ウクライナの支援拠点へのロシア軍の爆撃で26人死亡とキーウが発表 — 01:56
>     記事を読む (<https://www.bbc.co.uk/news/articles/cjy56dndlyz0o?at_medium=RSS&at_campaign=rss>)
> 2.  「Mogging」がコリンズ辞書の今年の言葉に。その意味を知っていますか？ — 01:52
>     記事を読む (<https://www.bbc.co.uk/news/articles/cve8rp085zzjo?at_medium=RSS&at_campaign=rss>)
> 3.  AmazonとTemuで「スターリングシルバー」として販売されたアクセサリーから有害化学物質を検出 — 01:49
>     記事を読む (<https://www.bbc.co.uk/news/articles/cm62yjx4dl0jo?at_medium=RSS&at_campaign=rss>)
> 4.  北朝鮮、63億ドル相当の過去最大級Binanceハッキングへの関与を否定 — 01:23
>     記事を読む (<https://www.bbc.co.uk/news/articles/c6rey4v53exgo?at_medium=RSS&at_campaign=rss>)
> 5.  折りたたみ式iPhoneが完売、Appleは次回入荷時期を示せず — 00:29
>     記事を読む (<https://www.bbc.co.uk/news/articles/c6n8dn457ypko?at_medium=RSS&at_campaign=rss>)

アクセスを許可したドメインは、以下のコマンドで確認できる。膨大なため、ここでは 'bbc' に絞って確認する。

```sh
sbx policy ls --type network --wide | grep bbc
```

許可を取り消すには、以下のコマンドを実行する。

```sh
sbx policy rm network --sandbox codex-sbx-codex-work --resource feeds.bbci.co.uk:443
sbx policy rm network --sandbox codex-sbx-codex-work --resource www.bbc.com:443
sbx policy rm network --sandbox codex-sbx-codex-work --resource bbc.com:443
```

再び、以下のコマンドを実行すると、許可されたドメインにbbc関連が含まれていないことが確認できる。

```sh
sbx policy ls --type network --wide | grep bbc
```


## まとめ {#まとめ}

Docker Sandboxは、AIエージェントを隔離するだけでなく、秘密情報を安全に扱うことができるようにしたり、外部との通信を制御することで危険なサイトへのアクセスを予防したりすることで、
AIエージェントを安全に使えるようにする仕組みである。

今までは、このような仕組みを実現するために `AGENTS.md` を利用したり、ハーネス(AIエージェントを動かす実行環境や制御を行う層)を利用したり、はたまた、Dockerで自前で隔離したり色々な手を使っていたが、それらに代わる、あるいはより強い制御を行うための選択肢にDocker Sandboxはなりうるものと感じた。

ただし、Docker Sandboxでは以下のようなリスクには対応できない。Docker Sandboxを使うからといっても、作業ディレクトリの絞り込み、最小権限、ネットワーク接続先の最小化には引き続き取り組んでいく必要がある。

1.  作業ファイルの改竄や破壊
2.  許可された接続先への意図しない情報送信や不正操作
3.  認証情報を使った不正な操作
4.  Sandbox内での特権操作(AIエージェントは sudo 権限を持ってコンテナ内で動作する)
5.  隔離機構(microVM)自体の脆弱性
