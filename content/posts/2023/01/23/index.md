---
title: "SAMを使ってみる"
date: 2023-01-23T10:50:30Z
categories:
  - Cloud
tags:
  - AWS
  - やってみた
authors:
  - sonohen
description: SAMとは、Serverless Application Modelの接頭辞で、サーバレスアプリケーションを素早く開発するためのツールセットです。CloudFormationにより、必要なリソースのデプロイが行われます。今回は、Cloud9環境を用いてハンズオンを行いました。
---

## SAMの使い方

大きな流れは以下の通りです。

1. サーバレスアプリケーションの雛形作成（`sam init`）
2. コーディング
3. ビルド（`sam build`）
4. ローカル環境でのテスト（`sam local start-api`）
5. デプロイ（`sam deploy`）

### サーバレスアプリケーションの雛形作成

```plain
sam init
```

今回は、以下のような構成を取りました。

- **テンプレートの種類**: AWS Quick Start Templates
- **使用するテンプレート**: Serverless API
- **ランタイム**: Node.js 16.x
- **X-Rayの使用有無**: No X-Ray
- **アプリケーション名**: sam-app

```bash
sam init
```

以下のとおり選択していきます。

```plain
You can preselect a particular runtime or package type when using the `sam init` experience.
Call `sam init --help` to learn more.

Which template source would you like to use?
        1 - AWS Quick Start Templates
        2 - Custom Template Location
Choice: 1

Choose an AWS Quick Start application template
        1 - Hello World Example
        2 - Multi-step workflow
        3 - Serverless API
        4 - Scheduled task
        5 - Standalone function
        6 - Data processing
        7 - Infrastructure event management
        8 - Lambda EFS example
        9 - Machine Learning
Template: 3

Which runtime would you like to use?
        1 - dotnet6
        2 - dotnetcore3.1
        3 - nodejs16.x
        4 - nodejs14.x
        5 - nodejs12.x
Runtime: 3

Based on your selections, the only Package type available is Zip.
We will proceed to selecting the Package type as Zip.

Based on your selections, the only dependency manager available is npm.
We will proceed copying the template using npm.

Would you like to enable X-Ray tracing on the function(s) in your application?  [y/N]: N

Project name [sam-app]: sam-app

Cloning from https://github.com/aws/aws-sam-cli-app-templates (process may take a moment)

    -----------------------
    Generating application:
    -----------------------
    Name: sam-app
    Runtime: nodejs16.x
    Architectures: x86_64
    Dependency Manager: npm
    Application Template: quick-start-web
    Output Directory: .

    Next steps can be found in the README file at ./sam-app/README.md


    Commands you can use next
    =========================
    [*] Create pipeline: cd sam-app && sam pipeline init --bootstrap
    [*] Validate SAM template: sam validate
    [*] Test Function in the Cloud: sam sync --stack-name {stack-name} --watch


SAM CLI update available (1.70.0); (1.57.0 installed)
To download: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html
```

### コーディング

ディレクトリ構成を確認しておきます。

```plain
.
├── buildspec.yml
├── env.json
├── events
│   ├── event-get-all-items.json
│   ├── event-get-by-id.json
│   └── event-post-item.json
├── package.json
├── README.md
├── src
│   └── handlers
│       ├── get-all-items.js
│       ├── get-by-id.js
│       └── put-item.js
├── template.yaml
└── __tests__
    └── unit
        └── handlers
            ├── get-all-items.test.js
            ├── get-by-id.test.js
            └── put-item.test.js
```

- **`buildspec.yml`**: CodeBuildの動作を決めるための定義ファイルです。アーティファクトはS3にZIP形式で置かれるようです。
- **`src/handlers/*.js`**: ソースコードの実体です。CFnの`template.yaml`から参照されているとおり、このソースコードがLambda関数の実体になります。
- **`__tests__/unit/handlers/*.js`**: テストコードです。`buildspec.yml`で、`pre_build`フェーズで実行されるようになっています。
- **`events/*.json`**: Lambda関数を起動するときに使う起動イベントの定義です。_Invocation events that you can use to invoke the function._
- **`env.json`**: `sam local invoke --env-vars env.json`とすることで、`template.yaml`に記載されている内容をオーバーライドできる仕組みのためのもののようです（[ローカルでの Lambda 関数の呼び出し](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-using-invoke.html)）。

### ビルド

`cd sam-app; sam build`で実行できます。

```bash
cd sam-app
sam build
```

以下のように出力されます。

- **アーティファクト**: `.aws-sam/build`
- **ビルドに使用したテンプレート**: `.aws-sam/build/template.yaml`

```plain
Building codeuri: /home/ec2-user/environment/sam-app runtime: nodejs16.x metadata: {} architecture: x86_64 functions: getAllItemsFunction, getByIdFunction, putItemFunction
Running NodejsNpmBuilder:NpmPack
Running NodejsNpmBuilder:CopyNpmrcAndLockfile
Running NodejsNpmBuilder:CopySource
Running NodejsNpmBuilder:NpmInstall
Running NodejsNpmBuilder:CleanUpNpmrc
Running NodejsNpmBuilder:LockfileCleanUp

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {stack-name} --watch
[*] Deploy: sam deploy --guided
```

### ローカル環境でのテスト

以下のコマンドにより、ローカル環境でテストできるエンドポイントが提供されます。

```bash
sam local start-api
```

`template.yaml`で定義された3つのハンドラーに対し、それぞれエンドポイントが提供されていることが分かります。

```plain
Mounting getAllItemsFunction at http://127.0.0.1:3000/ [GET]
Mounting getByIdFunction at http://127.0.0.1:3000/{id} [GET]
Mounting putItemFunction at http://127.0.0.1:3000/ [POST]
You can now browse to the above endpoints to invoke your functions. You do not need to restart/reload SAM CLI while working on your functions, changes will be reflected instantly/automatically. You only need to restart SAM CLI if you update your AWS SAM template
2023-01-23 12:12:43  * Running on http://127.0.0.1:3000/ (Press CTRL+C to quit)
```

ここで、Cloud9で別のターミナルを開き、`getAllItemsFunction`を呼び出してみます。

```bash
curl http://localhost:3000/
```

当然ですが、DynamoDBが適切にセットアップされていないのでエラーが返ってきます。また、一番最初に`getAllItemsFunction`を呼び出すときには、Dockerコンテナイメージのダウンロードが行われるため、ややレスポンスが悪いです。

```plain
Invoking src/handlers/get-all-items.getAllItemsHandler (nodejs16.x)
Image was not found.
Removing rapid images for repo public.ecr.aws/sam/emulation-nodejs16.x
Building image..............................................................................................................................
Skip pulling image and use local one: public.ecr.aws/sam/emulation-nodejs16.x:rapid-1.57.0-x86_64.

Mounting /home/ec2-user/environment/sam-app/.aws-sam/build/getAllItemsFunction as /var/task:ro,delegated inside runtime container
START RequestId: b38fd596-3599-4c48-bb0b-c4fe0906b982 Version: $LATEST
} version: '1.0': null,',4475962,12:42 +0000',e9808e',b-c4fe0906b982    INFO    received: {
2023-01-23T12:15:21.803Z        b38fd596-3599-4c48-bb0b-c4fe0906b982    INFO    response from: / statusCode: 404 body: Unable to call DynamoDB. Table resource not found.
END RequestId: b38fd596-3599-4c48-bb0b-c4fe0906b982
REPORT RequestId: b38fd596-3599-4c48-bb0b-c4fe0906b982  Init Duration: 1.49 ms  Duration: 508.13 ms     Billed Duration: 509 ms Memory Size: 128 MB     Max Memory Used: 128 MB
No Content-Type given. Defaulting to 'application/json'.
2023-01-23 12:15:21 127.0.0.1 - - [23/Jan/2023 12:15:21] "GET / HTTP/1.1" 404 -
```

### デプロイ

なんとなく動いたことの確認ができたので、デプロイしてみます。

```bash
sam deploy --guided
```

少々ログが長いので、[sam-deploy.log](sam-deploy.log)に置いておきました。

`--guided`をつけて`sam deploy`を起動すると、スタック名やリージョン等が聞かれます。聞かれた内容は`samconfig.toml`に記載され、今後は`sam deploy`を実行するだけで自動的にデプロイされます。

```toml
version = 0.1
[default]
[default.deploy]
[default.deploy.parameters]
stack_name = "sam-app"
s3_bucket = "aws-sam-cli-managed-default-samclisourcebucket-1ae5e5y3ql961"
s3_prefix = "sam-app"
region = "ap-northeast-1"
confirm_changeset = true
capabilities = "CAPABILITY_IAM"
disable_rollback = true
image_repositories = []
```

## APIを叩いてみる

### POST

実行コマンド

```bash
curl -X POST -H "Content-Type: application/json" -d '{"id":"1", "name":"sonohen"}' https://su7cqge7o3.execute-api.ap-northeast-1.amazonaws.com/Prod/
curl -X POST -H "Content-Type: application/json" -d '{"id":"2", "name":"sonohen2"}' https://su7cqge7o3.execute-api.ap-northeast-1.amazonaws.com/Prod/
```

戻り値

```json
{"id":"1","name":"sonohen"}
{"id":"2","name":"sonohen2"}
```

### GET (All Items)

実行コマンド

```bash
curl https://su7cqge7o3.execute-api.ap-northeast-1.amazonaws.com/Prod/
```

戻り値

```json
[
  { "id": "2", "name": "sonohen2" },
  { "id": "1", "name": "sonohen" }
]
```

### Get (By-Id)

実行コマンド

```bash
curl https://su7cqge7o3.execute-api.ap-northeast-1.amazonaws.com/Prod/1   # {"id":"1","name":"sonohen"} should be returned
```

戻り値

```json
{ "id": "1", "name": "sonohen" }
```

## 環境の削除

```bash
sam delete
```

出力例

```plain
        Are you sure you want to delete the stack sam-app in the region ap-northeast-1 ? [y/N]: y
        Are you sure you want to delete the folder sam-app in S3 which contains the artifacts? [y/N]: y
        - Deleting S3 object with key sam-app/11e6ad52d95b7ff61f7c5edee5989cc5
        - Could not find and delete the S3 object with the key sam-app/11e6ad52d95b7ff61f7c5edee5989cc5
        - Could not find and delete the S3 object with the key sam-app/11e6ad52d95b7ff61f7c5edee5989cc5
        - Deleting S3 object with key sam-app/a4776539efacb8d6b52ef4f5bcf5a08e.template
        - Deleting Cloudformation stack sam-app

Deleted successfully
```

## 感想

正直、SAMのハンズオンをやるかは、ものすごく悩んだ。DVAの教科書を見れば、コマンドの実行例とともにSAMの紹介がなされており、それを読めば十分だろうと思っていたからです。ただ実際にやってみると、SAMでHello Worldレベルのことをやるのに、このブログでメモを取りながらでも1時間くらいだし、最後、環境をきれいに削除してしまうのもCFnならではだなと思いました。実際に時間を使ってやってみると、自分の過去の似たような案件と比較してしまう...いや、してしまうという残念な感じよりも、このプロセスそのものが次の案件に向けては重要なんだろうなと思いました。
