---
title: "Elastic Beanstalkを試してみる"
date: 2023-01-22T03:26:59Z
categories:
  - 技術のこと
tags:
  - 技術のこと
authors:
  - sonohen
---

DVA試験（AWS Certified Developper - Associate）対策のため、Beanstalkをハンズオンしてみた。

<!--more-->

{{< toc >}}

## 目標

1. Elastic BeanstalkでHello Worldをしてみる。
2. Blue/Greenデプロイにより、Hello WorldをHello AWSに変えてみる。

## Elastic BeanstalkでHello Worldをしてみる。

### アプリケーションの作成

- アプリケーション名: beanstalk_trial
- プラットフォーム: Java
- プラットフォームのブランチ: Corretto((Amazonによる無料の長期サポートが提供されている、Java SE標準と互換性があると認定されているOpen JDKディストリビューションのこと。)) 17 running on 64bit Amazon Linux 2
- プラットフォームのバージョン: 3.4.3
- アプリケーションコード: サンプルアプリケーション

この後、CloudFormationテンプレートによりスタックが作成されていきます。

#### エラー

##### エラー事象

次に、`CloudFormation > スタック > awseb-e-e7d8kvxdpq-stack`を開き、`イベントタブ`を開いたところ、以下のようなエラーが発生し、スタックのステータスは`CREATE_FAILED`になっています。この時、`ElasticBeanstalk > 環境 > Beanstalktrial-env-2`の環境のヘルスは`保留中`になっています。

> The following resource(s) failed to create: [AWSEBV2LoadBalancer, AWSEBAutoScalingGroup].
>
> You must use a valid fully-formed launch template. No default subnet for availability zone: 'ap-northeast-1c'. (Service: AmazonAutoScaling; Status Code: 400; Error Code: ValidationError; Request ID: 7d99081a-1554-487c-b265-38b01661aa2e; Proxy: null)

このエラーの原因は、デフォルトサブネットが存在しないことです。過去にデフォルトVPCを削除した時に、一緒に削除されたのだと思います。そして、現在はデフォルトVPCのみ作成されている状況です。

Elastic Beanstalkの環境を削除、アプリケーションを終了した後、[デフォルトVPC](https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/default-vpc.html#create-default-vpc)の記載を参考に、`AWS CloudShell`から以下のコマンドでデフォルトVPCとデフォルトサブネットを作成します。起動する際、選択しているリージョンに注意してください。今回は、Elastic Beanstalkをap-northeast-1（東京リージョン）で起動したいので、それを指定した後、`AWS CloudShell`を起動しました。

#### 最終的に目指す構成

以下の通りです。

![デフォルトVPCの構成](images/default-vpc.png)

##### 対応1　デフォルトVPCの作成

```shell
aws ec2 create-default-vpc
```

出力例は以下です。

```plain
An error occurred (DefaultVpcAlreadyExists) when calling the CreateDefaultVpc operation: A Default VPC already exists for this account in this region.
```

既にデフォルトVPCが存在すると言われます。デフォルトVPCの`VpcId`を調べます。

```shell
aws ec2 describe-vpcs --filter Name=is-default,Values=true --query 'Vpcs[].[VpcId]' --output text
```

出力例は以下です。

```plain
vpc-0f48a5ddd72f1781f
```

##### 対応2　既に存在するサブネットの削除

（勝手に作った）既に存在するサブネットを削除しておきます。

```shell
for target_subnet in `aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-0f48a5ddd72f1781f --query 'Subnets[].[SubnetId]' --output text`
do
  aws ec2 delete-subnet --subnet-id $target_subnet
done
```

削除されたことを確認します。

```shell
aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=vpc-0f48a5ddd72f1781f \
  --query 'Subnets[].[SubnetId]' \
  --output text
```

##### 対応3　デフォルトサブネットの作成

```shell
availability-zones=(ap-northeast-1a ap-northeast-1c ap-northeast-1d)

for availability-zone in ${availability-zones[@]}
do
  aws ec2 create-default-subnet --availability-zone $availability-zone
done

unset availability-zones
```

作成されたことを確認します。

```shell
aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=vpc-0f48a5ddd72f1781f \
  --filters Name=state,Values=available \
  --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock]'
```

出力例は以下です。

```json
[
    [
        "subnet-090132d78642c5909",
        "ap-northeast-1d",
        "172.31.32.0/20"
    ],
    [
        "subnet-0a941d6e7b4ae578c",
        "ap-northeast-1c",
        "172.31.0.0/20"
    ],
    [
        "subnet-0374fa703f83f7ae1",
        "ap-northeast-1a",
        "172.31.16.0/20"
    ]
]
```

ドキュメントによると、デフォルトサブネットのCIDRは`172.31.0.0/20, 172.31.16.0/20, 172.31.32.0/20`の3つであるということなので、きちんと作成されたようです。

##### 確認　インターネットゲートウェイの状況

デフォルトVPCにアタッチされているインターネットゲートウェイの`InternetGatewayId`を調べます。

```shell
aws ec2 describe-internet-gateways \
  --filter Name=attachment.vpc-id,Values=vpc-0f48a5ddd72f1781f \
  --filter Name=attachment.state,Values=available \
  --query 'InternetGateways[].[InternetGatewayId]' \
  --output text
```

出力例は以下です。

```plain
igw-0adc27eae43d8714d
```

`0.0.0.0/0`宛の通信が上記のInternetGatewayを通るように設定されているか、ルートテーブルを確認します。

```shell
aws ec2 describe-route-tables \
  --filter Name=vpc-id,Values=vpc-0f48a5ddd72f1781f \
  --filter Name=route.destination-cidr-block,Values=0.0.0.0/0 \
  --filter Name=route.gateway-id,Values=igw-0adc27eae43d8714d \
  --output text
```

出力例は以下です。

```json {linenos=table,hl_lines=["15-18", 27]}
{
    "RouteTables": [
        {
            "Associations": [],
            "PropagatingVgws": [],
            "RouteTableId": "rtb-0ef8c99720a501497",
            "Routes": [
                {
                    "DestinationCidrBlock": "172.31.0.0/16",
                    "GatewayId": "local",
                    "Origin": "CreateRouteTable",
                    "State": "active"
                },
                {
                    "DestinationCidrBlock": "0.0.0.0/0",
                    "GatewayId": "igw-0adc27eae43d8714d",
                    "Origin": "CreateRoute",
                    "State": "active"
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "default-public-rtb"
                }
            ],
            "VpcId": "vpc-0f48a5ddd72f1781f",
            "OwnerId": "436589084651"
        }
    ]
}
```

`0.0.0.0/0`宛の通信が`igw-0adc27eae43d8714d`を通るように設定されていることが確認できました。

