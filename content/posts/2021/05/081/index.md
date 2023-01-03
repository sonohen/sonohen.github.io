---
title: "Rcloneの使い方"
date: 2021-05-05T21:56:43Z
description: "Rcloneという複数のクラウドドライブに対応したCLIベースのプログラムがあります。それを使ってonedriveにアクセスしましたので、その方法やユースケースを紹介します。"
categories:
  - "技術のこと"
tags:
  - "技術のこと"
---

Rcloneという複数のクラウドドライブに対応したCLIベースのプログラムがあります。それを使ってonedriveにアクセスしましたので、その方法やユースケースを紹介します。

<!--more-->

### Rcloneとは

> Rclone is a command line program to manage files on cloud storage. It is a feature rich alternative to cloud vendors' web storage interfaces. Over 40 cloud storage products support rclone including S3 object stores, business & consumer file storage services, as well as standard transfer protocols.

つまるところ、Rcloneはクラウドストレージを操作するためのコマンドライン・インタフェースであり、40を超えるクラウドサービスに加え、標準的な転送プロトコル（SFTP等）もサポートしているというものです。

### 使い方

使用する前に、設定を行う必要があります。ここでは、`onedrive`を例に記載します。

`**`に囲まれている箇所が入力する箇所です。

```shell
$ rclone config
2021/05/05 21:34:53 NOTICE: Config file "/home/sonohen/.config/rclone/rclone.conf" not found - using defaults
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n
name> **onedrive**
Type of storage to configure.
Enter a string value. Press Enter for the default ("").
Choose a number from below, or type in your own value
 1 / 1Fichier
   \ "fichier"
 2 / Alias for an existing remote
   \ "alias"
 3 / Amazon Drive
   \ "amazon cloud drive"
 4 / Amazon S3 Compliant Storage Providers including AWS, Alibaba, Ceph, Digital Ocean, Dreamhost, IBM COS, Minio, and Tencent COS
   \ "s3"
 5 / Backblaze B2
   \ "b2"
 6 / Box
   \ "box"
 7 / Cache a remote
   \ "cache"
 8 / Citrix Sharefile
   \ "sharefile"
 9 / Compress a remote
   \ "compress"
10 / Dropbox
   \ "dropbox"
11 / Encrypt/Decrypt a remote
   \ "crypt"
12 / Enterprise File Fabric
   \ "filefabric"
13 / FTP Connection
   \ "ftp"
14 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
15 / Google Drive
   \ "drive"
16 / Google Photos
   \ "google photos"
17 / Hadoop distributed file system
   \ "hdfs"
18 / Hubic
   \ "hubic"
19 / In memory object storage system.
   \ "memory"
20 / Jottacloud
   \ "jottacloud"
21 / Koofr
   \ "koofr"
22 / Local Disk
   \ "local"
23 / Mail.ru Cloud
   \ "mailru"
24 / Mega
   \ "mega"
25 / Microsoft Azure Blob Storage
   \ "azureblob"
26 / Microsoft OneDrive
   \ "onedrive"
27 / OpenDrive
   \ "opendrive"
28 / OpenStack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
29 / Pcloud
   \ "pcloud"
30 / Put.io
   \ "putio"
31 / QingCloud Object Storage
   \ "qingstor"
32 / SSH/SFTP Connection
   \ "sftp"
33 / Sugarsync
   \ "sugarsync"
34 / Tardigrade Decentralized Cloud Storage
   \ "tardigrade"
35 / Transparently chunk/split large files
   \ "chunker"
36 / Union merges the contents of several upstream fs
   \ "union"
37 / Webdav
   \ "webdav"
38 / Yandex Disk
   \ "yandex"
39 / Zoho
   \ "zoho"
40 / http Connection
   \ "http"
41 / premiumize.me
   \ "premiumizeme"
42 / seafile
   \ "seafile"
Storage> **26**

*See help for onedrive backend at: https://rclone.org/onedrive/*

OAuth Client Id
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_id>**[Blank]**
OAuth Client Secret
Leave blank normally.
Enter a string value. Press Enter for the default ("").
client_secret>**[Blank]**
Choose national cloud region for OneDrive.
Enter a string value. Press Enter for the default ("global").
Choose a number from below, or type in your own value
 1 / Microsoft Cloud Global
   \ "global"
 2 / Microsoft Cloud for US Government
   \ "us"
 3 / Microsoft Cloud Germany
   \ "de"
 4 / Azure and Office 365 operated by 21Vianet in China
   \ "cn"
region> **1**
Edit advanced config? (y/n)
y) Yes
n) No (default)
y/n> **n**
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes (default)
n) No
y/n> **y**
If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth?state=xxx
Log in and authorize rclone for access
Waiting for code...
**ここでブラウザが開くので、Microsoftアカウントでログインし、画面の指示に従う。**
Got code
Choose a number from below, or type in an existing value
 1 / OneDrive Personal or Business
   \ "onedrive"
 2 / Root Sharepoint site
   \ "sharepoint"
 3 / Sharepoint site name or URL (e.g. mysite or https://contoso.sharepoint.com/sites/mysite)
   \ "url"
 4 / Search for a Sharepoint site
   \ "search"
 5 / Type in driveID (advanced)
   \ "driveid"
 6 / Type in SiteID (advanced)
   \ "siteid"
 7 / Sharepoint server-relative path (advanced, e.g. /teams/hr)
   \ "path"
Your choice> **1**
Found 1 drives, please select the one you want to use:
0:  (personal) id=xxx
Chose drive to use:> **0**
Found drive 'root' of type 'personal', URL: https://onedrive.live.com/?cid=xxx
Is that okay?
y) Yes (default)
n) No
y/n> **y**
--------------------
[onedrive]
type = onedrive
region = global
token = {"access_token":"","token_type":"Bearer","refresh_token":"","expiry":"2021-05-05T22:36:16.565429024+09:00"}
drive_id = xxx 
drive_type = personal
--------------------
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> **y** 
Current remotes:

Name                 Type
====                 ====
onedrive             onedrive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> **q** 
```

### 使い方

#### リモート側のファイルを確認する

```shell
$ rclone ls onedrive:
```

#### リモートからファイルをダウンロードする

```shell
$ rclone copy -P onedrive: /path/to/download
```

他のコマンドは、[詳細](https://rclone.org/docs/)を参照。
