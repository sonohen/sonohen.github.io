---
title: "NixOSでZFSからデータを救出する"
author: ["sonohen"]
date: 2026-10-26
tags: ["NixOS"]
categories: ["Linux"]
draft: true
toc: true
description: "UbuntuからNixOSに移行するにあたり、ZFSなパーティションからデータを救出する必要があった。Nix Shellをうまく使うことでデータの救出に成功した。"
---

## 概要 {#概要}

Ubuntu Linuxを使用していたが、自分のLinux環境をファイルで定義できるNixOSに興味を持ち、この週末に移行した。
Ubuntu LinuxではLUKSで暗号化したZFSパーティションを使用していたため、NixOSからZFSなパーティションをマウントしてデータ移行する必要があった。その対応の記録をしたので、ブログにまとめることにする。


## 環境 {#環境}

-   NixOS 26.05
-   ThinkPad E14 Gen 3
    -   `/dev/nvme0n1`: KBG40ZNT256G(Toshiba) - NixOSインストール済
    -   `/dev/nvme1n1`: Samsung SSD 980 500GB - Ubuntu Linuxインストール済


## 目的 {#目的}

以下を実現することを目的とする。

-   `/dev/nvme1n1` から `/dev/nvme0n1` に `/home` のデータを移行する
-   `/dev/nvme1n1` を消去し、新たにext4のパーティションを作成し、それをNixOSの `/home` にマウントする


## データ移行の流れ {#データ移行の流れ}

大きくは以下の4つの手順を踏む。

1.  現状の把握
2.  LUKS鍵の取り出し
3.  ZFSパーティションのマウントとデータの移行
4.  ディスクのフォーマットと /home ヘのマウント


## 現状の把握 {#現状の把握}


### ディスクの状況 {#ディスクの状況}

```sh
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINTS,MODEL
```

```text
NAME        PATH             SIZE TYPE FSTYPE     UUID                                 MOUNTPOINTS MODEL
nvme0n1     /dev/nvme0n1   238.5G disk                                                             KBG40ZNT256G TOSHIBA MEMORY
├─nvme0n1p1 /dev/nvme0n1p1     2G part vfat       E29B-9551                            /boot
├─nvme0n1p2 /dev/nvme0n1p2    24G part swap       15f27874-dfbd-4afb-92cb-56bd089cea04 [SWAP]
└─nvme0n1p3 /dev/nvme0n1p3 212.5G part ext4       ad329431-4846-495f-b312-67d24b2a005c /nix/store
                                                                                       /
nvme1n1     /dev/nvme1n1   465.8G disk                                                             Samsung SSD 980 500GB
├─nvme1n1p1 /dev/nvme1n1p1     1G part vfat       FACF-1404
├─nvme1n1p2 /dev/nvme1n1p2     2G part zfs_member 12601984913637652299
├─nvme1n1p3 /dev/nvme1n1p3     8G part
└─nvme1n1p4 /dev/nvme1n1p4 454.7G part zfs_member 14549146316260236921
```


### `ZFS` の状態 {#zfs-の状態}

あらかじめ `configuration.nix` に以下の記述を入れたうえでビルドしておく必要がある。

```nix
networking.hostId = "1aeba738";
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
```

なお `networking.hostId` には、以下を実行して取得した値を設定する。

```sh
head -c 8 /etc/machine-id
```

以下のように `nix shell nixpkgs#zfs` を実行すれば環境を汚すこともないので便利である。

```sh
sudo nix shell nixpkgs#zfs -c zpool import
```

無事に認識されていることがわかる。

```text
  pool: bpool
    id: 12601984913637652299
 state: ONLINE
status: The pool was last accessed by another system.
action: The pool can be imported using its name or numeric identifier and
	the '-f' flag.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-EY
config:

	bpool                              ONLINE
	  nvme-eui.002538db11c4531d-part2  ONLINE

  pool: rpool
    id: 14549146316260236921
 state: ONLINE
status: The pool was last accessed by another system.
action: The pool can be imported using its name or numeric identifier and
	the '-f' flag.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-EY
config:

	rpool                              ONLINE
	  nvme-eui.002538db11c4531d-part4  ONLINE
```

ちなみに `rpool` がUbuntu Linuxで言うところの `/` である。


## LUKS鍵の取り出し {#luks鍵の取り出し}

Ubuntu Linuxの `/` をマウントするためのディレクトリとして `/mnt/zfs-recovery/` を作成する。マウントし `rpool` の状態を確認する。

```sh
sudo nix shell nixpkgs#zfs -c zpool import -f -o readonly=on -N -R /mnt/zfs-recovery rpool
sudo nix shell nixpkgs#zfs -c zfs list -r -o name,mountpoint,canmount,encryption,keystatus rpool
```

```text
NAME                                              MOUNTPOINT                                 CANMOUNT  ENCRYPTION   KEYSTATUS
rpool                                             /mnt/zfs-recovery                          off       aes-256-gcm  unavailable
rpool/ROOT                                        none                                       off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3                          /mnt/zfs-recovery                          on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/srv                      /mnt/zfs-recovery/srv                      on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/usr                      /mnt/zfs-recovery/usr                      off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/usr/local                /mnt/zfs-recovery/usr/local                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var                      /mnt/zfs-recovery/var                      off       aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/games                /mnt/zfs-recovery/var/games                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib                  /mnt/zfs-recovery/var/lib                  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/AccountsService  /mnt/zfs-recovery/var/lib/AccountsService  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/NetworkManager   /mnt/zfs-recovery/var/lib/NetworkManager   on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/apt              /mnt/zfs-recovery/var/lib/apt              on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/lib/dpkg             /mnt/zfs-recovery/var/lib/dpkg             on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/log                  /mnt/zfs-recovery/var/log                  on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/mail                 /mnt/zfs-recovery/var/mail                 on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/snap                 /mnt/zfs-recovery/var/snap                 on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/spool                /mnt/zfs-recovery/var/spool                on        aes-256-gcm  unavailable
rpool/ROOT/ubuntu_094mo3/var/www                  /mnt/zfs-recovery/var/www                  on        aes-256-gcm  unavailable
rpool/USERDATA                                    none                                       off       aes-256-gcm  unavailable
rpool/USERDATA/home_lqdl5w                        /mnt/zfs-recovery/home                     on        aes-256-gcm  unavailable
rpool/USERDATA/root_lqdl5w                        /mnt/zfs-recovery/root                     on        aes-256-gcm  unavailable
rpool/keystore                                    -                                          -         off          -
```

`rpool/USERDATA/home_lqdl5w` が `/home` のデータセットであることがわかる。
`KEYSTATUS` が `unavailable` になっているので、 `encryptionroot` を確認する。

```sh
sudo nix shell nixpkgs#zfs -c zfs get -o property,value encryptionroot,keylocation,keyformat,keystatus,mountpoint,canmount rpool
```

```text
PROPERTY        VALUE
encryptionroot  rpool
keylocation     file:///run/keystore/rpool/system.key
keyformat       raw
keystatus       unavailable
mountpoint      /mnt/zfs-recovery
canmount        off
```

Ubuntu Linux では `rpool/keystore/system.key` が存在し、起動時に `/run/keystore/rpool` にマウントされる。

```sh
sudo nix shell nixpkgs#cryptsetup -c cryptsetup open --readonly /dev/zvol/rpool/keystore keystore-rpool
```

以下のコマンドを実行し、確認する。

```sh
lsblk -f /dev/mapper/keystore-rpool
```

```text
NAME           FSTYPE FSVER LABEL          UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
keystore-rpool ext4   1.0   keystore-rpool d18e3c3c-d0fb-4507-94bc-61327e95edc4
```

期待される場所(`keylocation     file:///run/keystore/rpool/system.key`)で参照できるようにマウントする。

```sh
sudo mkdir -p /run/keystore/rpool
sudo mount -o ro,noload /dev/mapper/keystore-rpool /run/keystore/rpool
sudo test -s /run/keystore/rpool
sudo nix shell nixpkgs#zfs -c zfs load-key rpool
```


## ZFSパーティションのマウントとデータの移行 {#zfsパーティションのマウントとデータの移行}

ここまでで rpool を読み込むための鍵を入手できたので `rpool/USERDATA/home_lqdl5w` をマウントする。

```sh
sudo nix shell nixpkgs#zfs -c zpool get altroot rpool
sudo nix shell nixpkgs#zfs -c zfs get mountpoint,canmount,keystatus rpool/USERDATA/home_lqdl5w
```

`keystatus = available`, `canmount = on` であることが確認できる。

```text
NAME   PROPERTY  VALUE              SOURCE
rpool  altroot   /mnt/zfs-recovery  local
NAME                        PROPERTY    VALUE                   SOURCE
rpool/USERDATA/home_lqdl5w  mountpoint  /mnt/zfs-recovery/home  local
rpool/USERDATA/home_lqdl5w  canmount    on                      local
rpool/USERDATA/home_lqdl5w  keystatus   available               -
```

マウントし、内容を確認する。

```sh
sudo mkdir -p /mnt/zfs-recovery/home
sudo nix shell nixpkgs#zfs -c zfs mount rpool/USERDATA/home_lqdl5w
sudo findmnt -S rpool/USERDATA/home_lqdl5w
ls -la /mnt/zfs-recovery/home
```

```text
TARGET             SOURCE                 FSTYPE OPTIONS
/mnt/zfs-recovery/home
                   rpool/USERDATA/home_lqdl5w
                                          zfs    ro,nodev,relatime,xattr,posixac
total 22
drwxr-xr-x   3 root    root    3 Oct  4 09:43 .
drwxr-xr-x   3 root    root 4096 Oct 25 14:33 ..
drwxr-x---+ 32 sonohen 1000   59 Oct 24 23:07 sonohen
```

ここまできたら、あとは `rsync` を使用してデータを救出すればよい。
`/dev/nvme1n1p1` を `/mnt/new-home` にマウントし、 `/home` の全データを `rsync` で移行する。

```sh
sudo mkdir -p /mnt/new-home
sudo mount /dev/nvme1n1p1 /mnt/new-home
sudo nix shell nixpkgs#rsync -c rsync -aHAXx --numeric-ids /home/ /mnt/new-home/
blkid -s UUID -o value /dev/nvme1n1p1
```


## ディスクのフォーマットと /home へのマウント {#ディスクのフォーマットと-home-へのマウント}


### `rpool` の切り離し {#rpool-の切り離し}

```sh
sudo nix shell nixpkgs#zfs -c zfs unmount rpool/USERDATA/home_lqdl5w
sudo umount /run/keystore/rpool
sudo nix shell nixpkgs#cryptsetup -c cryptsetup close keystore-rpool
sudo nix shell nixpkgs#zfs -c zpool export rpool
```

切り離し後の確認を行う。nvme1n1がマウントされていないことを確認する。

```sh
sudo findmnt -T /
sudo findmnt -T /boot
sudo findmnt -T /home
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS /dev/nvme1n1
```

```text
TARGET SOURCE         FSTYPE OPTIONS
/      /dev/nvme0n1p3 ext4   rw,relatime
TARGET SOURCE FSTYPE OPTIONS
/boot  /dev/nvme0n1p1
              vfat   rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=is
TARGET SOURCE         FSTYPE OPTIONS
/      /dev/nvme0n1p3 ext4   rw,relatime
NAME          SIZE MODEL                 FSTYPE     MOUNTPOINTS
nvme1n1     465.8G Samsung SSD 980 500GB
├─nvme1n1p1     1G                       vfat
├─nvme1n1p2     2G                       zfs_member
├─nvme1n1p3     8G
└─nvme1n1p4 454.7G                       zfs_member
```


### パーティションを作成する {#パーティションを作成する}

この作業は破壊的であるため、データのバックアップが完了していることを再確認してから実行する。

```sh
sudo nix shell nixpkgs#gptfdisk -c sgdisk --clear --new=1:0:0 --typecode=1:8300 -change-name=1:home /dev/nvme1n1
sudo nix shell nixpkgs#parted -c partprobe /dev/nvme1n1
sudo udevadm settle
sudo wipefs -a /dev/nvme1n1p1
sudo mkfs.ext4 -L home /dev/nvme1n1p1
```

```sh
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS /dev/nvme1n1
```

```text
NAME          SIZE TYPE FSTYPE MOUNTPOINTS
nvme1n1     465.8G disk
└─nvme1n1p1 465.8G part ext4
```


### `configuration.nix` の修正 {#configuration-dot-nix-の修正}

以下を追記し、リビルドして再起動する。再起動後 `/dev/nvme1n1p1` が `/home` にマウントされていることを確認する。なお、=/dev/nvme1n1p1= (ext4ファイルシステム) のUUIDは `blkid -s UUID -o value /dev/nvme1n1p1` で取得できる。

```nix
fileSystems."/home" = {
  device = "/dev/disk/by-uuid/66cbb556-4c8b-4480-8ec5-b40484996a4b";
  fsType = "ext4";
};
```


### 後始末 {#後始末}

冒頭で `configuration.nix` に追記した以下の記述は不要なので消す。

```nix
networking.hostId = "1aeba738";
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
```


## 感想 {#感想}

順を追って対応すればなんら難しくはないのだが、面倒臭い作業ではある。当面対応したくはないのだが、また機会がありそうなので、記録しておく。
