---
title: "ローカルLLMでSpec Driven Developmentは、まだ難しかった"
date: 2026-02-14T00:00:00+0900
author: "sonohen"
categories: ["Programming"]
tags: ["やってみた", "Generative AI"]
description: ローカルLLM（LM Studio + Aider）でSpec Driven Developmentを実践しようとしたものの、モデルの推論性能とハードウェアの制約という二重の壁に阻まれた。その失敗の記録と、そこから得た学びをまとめる。結論から言うと、2026年時点で個人のMacBook M3 24GB環境においてローカルLLMでSpec Driven Developmentを実用するのは現実的ではなかった。本記事は、その失敗の記録である。
---

## TL; DR

- ローカルLLM（LM Studio） + AiderでSpec Driven Development（SDD）を試したが、実用には至らなかった
- 14Bクラスのモデルでは推論性能が不足し、以下のような問題が頻発した。
  - 仕様外のファイル生成
  - 過剰修正
  - 英語/日本語のコード再生成ループ
- 一方で、より大きなモデルは メモリ制約（MacBook M3 / 24GB）で動かせない
- Deepseek系モデルでは、エンジンの設計上のトレードオフに直面した
  - MLX：OOMで即クラッシュ
  - llama.cpp：OOM後も動き続けるが推論崩壊が発生
- 推論性能が低いほど、開発者側に高度な仕様記述スキルが要求される
  - ローカルLLMでSDDをするには、SDDが不要なほどの知識と熟練が必要
- Context Lengthは後から調整するものではなく、KV Cacheとメモリ量を踏まえた事前の設計判断が必須
- ローカルLLMは「クラウドLLMの安価な代替」ではなく、オンプレAI基盤としての設計・運用能力を要求される計算基盤
- 結論としては、現時点の個人環境では、ローカルLLMで実用的なSDDを行うのは現実的ではない。

## きっかけ

_Spec Driven Development_ （SDD）を試してみたいと思っていた。ClaudeなどのクラウドLLMを使えばそのまま実践できるが、実験を何度も繰り返すにはコストが気になる。そこで「LM StudioのOpenAI互換APIにAiderのバックエンドを向ければ、ローカルでSDDを動かせるのでは」と考えた。

ちなみにここでいうSDDとは、AIに対して厳密な仕様書（プロンプト）を与えることで実装を自律的に行わせる開発手法を指している。

### 環境

- モデル: `qwen/qwen2.5-coder-14b`
- MacBook M3（24GB RAM）
- LM Studioバージョン0.4.2+2
- aider 0.82.3

## 試行の記録

### Qwenでの失敗：14Bの壁

Aiderを立ち上げ、Kotlinアプリの仕様書を渡して実装を指示してみた。

#### 仕様書

```markdown
- Objective

Users will be motivated to streak their good habits using this app.

- Function

This app provides users the following functions:

User can:

FUNC-1. Create, update and delete habits
FUNC-2. Track their progress. The definition of "progress" is "how long the user keep doing" not "how many times the user did a week."
FUNC-3. Even the habits are deleted, user can track their progress.

User cannot:

1. Track the progress by recording "how many times they did". The app has status only "done, or not done."

- MVP
  First, FUNC-1 should be implemented. Other functions are not required now.

- Architecture

This is Android app. The project setting is as follows:

- **Name**: Habit Tracker
- **Package name**: net.sonohen.app.habittracker
- **Save location**: /Users/sonohen/code/net.sonohen.app.habittracker
- **Language**: Kotlin
- **Minimum SDK**: API 24 ("Nougat"; Android 7.0)
- **Build configuration language**: Kotlin DSL (build.gradle.kts) [Recommended]

* Implementation Constraints

- Implement ONLY what is specified in this document
- Do NOT add features beyond MVP scope
- Do NOT modify UI text without explicit instruction
- Do NOT add "nice to have" improvements

* Source Structure
  `~/code/net.sonohen.app.habittracker/app/src/main/java/net/sonohen/app/habittracker`

* Testing Source (For unit test)
  `~/code/net.sonohen.app.habittracker/app/src/test/java/net/sonohen/app/habittracker`

* Testing Source (For testing on Android device or emulator)
  `~/code/net.sonohen.app.habittracker/app/src/main/java/net/sonohen/app/habittracker`
```

すると、3つの問題が表面化した。

1. **意図しない場所へのファイル作成**: 仕様書に書いていないディレクトリにソースファイルが生成される。（パスを指定しているにもかかわらず）
2. **過剰修正**: 画面に表示されるメッセージについて、「カジュアルにせよ」という指示をしていないにもかかわらず「ユーザはカジュアルにせよと指示している」と言って聞かず、延々と修正を繰り返す。
3. **英語/日本語ループ**: —英語で推論/思考を行なってコードを生成した後、日本語でも（英語時と）まったく同じコードを再生成するループに入ってしまう。

根本的な問題は2点に整理できる。

1. **モデルの制約**: 14B程度ではタスクを分解して自律的に動作するには推論性能が不足している。
2. **メモリの制約**: 14B超のモデルはMacBook M3（24GB RAM）では動かせない。長いコンテキストを保持しつつ、Android StudioやChromeなどでメモリを消費していると、スワップ回避や量子化率を下げて精度を確保することを考慮しても、実用的には48GB以上のメモリが欲しくなる。

### Deepseekへの乗り換えとクラッシュ・推論崩壊

14Bの壁を越えるべく、M3 MacBookでもGPUに完全オフロードできる _Deepseek R1 0528 Qwen3 8B_ に切り替えた。

まず`mlx_lm`エンジン（MLXバックエンド）で試したところ、以下のエラーでクラッシュした。

```python
litellm.APIConnectionError: APIConnectionError: OpenAIException - Error in iterating prediction stream: Exception:
Encountered fatal exception in the backend scheduler: Traceback (most recent call last):
  File ".../mlx_engine/model_kit/batched_model_kit.py", line 216, in _generate_with_exception_handling
    self._generate()
  File ".../mlx_engine/model_kit/batched_model_kit.py", line 338, in _generate
    responses = batch_generator.next()
                ^^^^^^^^^^^^^^^^^^^^^^
  File ".../mlx_lm/generate.py", line 1266, in next
    return self._next()
```

MLXはOut of Memory（OOM）により物理メモリの割り当てに失敗すると、以降の推論崩壊を防止するために処理を停止する設計になっている。そのためOOMが発生した瞬間にクラッシュする。今回の場合、生成されたトークンが11,000を超えたあたりでクラッシュしている。

次にクラッシュを回避するため、DeepseekをMLXフォーマットからGGUFフォーマットに変更し、`llama.cpp`バックエンドに切り替えたところ、11,000トークンを超えても回答を生成するようにはなった。

しかし、今度は **推論崩壊** が発生した。`llama-cli`はOOMが発生しても`ctx_pos` / `n_past`が進み続ける設計であり、初期化が保証されていないKV Cacheを文脈として使い続けるため、推論が崩壊しながら処理を続けてしまうのだ。

これは、両者の良し悪しではなく、設計思想によるトレードオフである。

## 失敗から学んだこと

### 推論性能と開発者スキルはトレードオフになる

SDDは「仕様書を書けばAIがコードを生成する」ものだが、AIの推論性能が低い場合は開発者の仕様記述能力への要求が高まる。推論性能に期待できない環境では、Javaならソースコードの配置先、Unit Testの書き方、UIのレイアウト方針、データベース設計など、これらすべてを厳密な仕様として事前に記述する責任が開発者に生まれる。

逆説的だが、 **ローカルLLMでSDDを実践するには、SDDを必要としないほどのスキルが求められる** ことになる。

### 過剰修正とループへの対処

モデルのタスク分解能力が低いと「要求していない箇所まで修正する」「同じコードを別言語（英語の次に日本語で推論・思考が行われるなど）のプロンプトで再生成するループに入る」という問題行動が発生しやすい。対策として、1つの指示を可能な限り小さく・明確に絞り込み、1ファイル・1関数単位でやり取りするのが現実的だと感じた。

### Context LengthはKV Cacheとメモリの設計判断

Context Lengthは単に大きく設定すれば良いというものではない。Context Lengthが要求するKV Cacheのサイズは、モデルのアーキテクチャと量子化ビット数によって決まる動的メモリ量だ。OOMが発生すると、エンジンによってはクラッシュで止まり（MLX）、あるいは推論崩壊しながら動き続ける（llama.cpp）。

**Context Lengthの設定は、モデルとハードウェアのメモリ量を踏まえた設計判断として事前に確定させる必要がある[^1]。**

[^1]: とすると、ClaudeやGeminiという多数がアクセスするLLMのパラメータや基盤設計がどうなっているのかは非常に気になるところである。

### ローカルLLMを使うには、オンプレミスのインフラ設計で求められるような設計を開発者に要求する

今回最も印象に残ったのは、「ローカルLLMはクラウドLLMの手軽な代替ではない」という認識だ。ローカルLLMはマシンスペックさえあれば手軽に試せるという文脈で紹介されがちであるが、実際に使おうと思うとかなり難しい。しかし、クラウドで提供される生成AIであればインフラのことを意識しなくて済む。しかしローカルLLMでは、モデルの選定・量子化方式・推論エンジンの選択・Context Lengthとメモリの関係など、これらをオンプレミス環境のサーバ運用と同等の感覚で設計する必要がある。

仕事では「セキュリティを要求する顧客にはオンプレの生成AIを提供すべきではないか」という議論が時たま起こるが、決してそんな単純な判断軸ではないと体感した。

## まとめ

ローカルLLM（LM Studio + Aider）でSpec Driven Developmentを試みたが、モデルの推論性能とハードウェアの制約という2つの壁に阻まれ、実用的なSDDには至らなかった。

主な学びをまとめると以下の通りになる。

- 推論性能が低いほど、開発者の仕様記述スキルへの要求が高まる（推論性能と人間スキルのトレードオフ）
- 過剰修正・言語ループを防ぐには指示を細かく分割する
- Context LengthはKV Cacheとメモリの設計判断であり、後から調整するものではない
- ローカルLLMはオンプレ運用と同等の設計思想が必要な計算基盤である

今後の展望としては、 _Spec Kit_ で仕様・機能を洗い出し、 _Aider_ は実装フェーズのみに限定するという役割分担も検討したい。また、クラッシュと推論崩壊を防ぐために各種パラメータの設定と格闘した記録は、[次の記事](../../../2026/02/1501/)に書いている。
