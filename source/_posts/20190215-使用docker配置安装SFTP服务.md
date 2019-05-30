---
title: 使用docker配置安装SFTP服务
tags:
  - docker
  - sftp
categories:
  - [运维]
abbrlink: 7245841c
date: 2019-02-15 14:17:47
---

这个想法的起因是我需要给同事们共享 8 个 G 的会议视频，而我在公司里的 OwnCloud 账户容量不够，运维同学说运行 OwnCloud 的服务器磁盘不够了，也没配 LVM，不好增加容量。
原本准备用传统的 FTP 来上传和分享，但转头在使用 OwnCloud 的时候发现它可以配置外部存储，支持 SFTP 但不支持 FTP，所以就开始配置这个 SFTP 的流程了。

## 安装 docker 环境和设置国内源

这部分材料比较多，可以参见我的[ubuntu 17.04 下安装 docker 国内镜像教程](/p/1a833b74.html)，我就不在这里说了，反正就是需要一个方便可用的 docker 环境，国外源下载很慢，配置下国内源以节约时间。

## 使用镜像文件启动基于 Docker 的 SFTP 服务

SFTP 服务我简单搜索了下，简单的解释就是 FTP 的安全版本，是基于 SSH 登录服务的文件传输服务，常用的 openssh 软件包都内置了这项功能。
但正是因为它和 SSH 服务绑定了，所以配置起来总感觉影响太广，也不方便进行用户的增删，所以配置一个 docker 来隔离这项功能是比较舒服的方案。

### 编写配置文件

这里我们使用了[atmoz/sftp](https://github.com/atmoz/sftp/)这个 dockerfile，在启动前我们要在文件夹下创建这样几个文件/文件夹

- **users.conf 文件**

这个文件定义了可以登录的用户信息，包括用户名和密码，后面的用户 id 保证不重复，groupid 任意填写（推荐全部相同即可）

```bash
vim users.conf
```

单行格式： **username:password:userid:groupid**

```
foo:123:1001:100
bar:abc:1002:100
baz:xyz:1003:100
bazz:xyz:1004:100
bay:xyz:1005:100
```

- **share 文件夹**

```bash
mkdir share
```

该文件夹下的文件将会映射到所有用户的根目录下，并且是只读权限，用户可以下载其中的文件

- **sftp.d/init.sh 文件**

sftp.d 文件夹将映射到 docker 中的启动目录，这样在创建 docker 的时候会运行该目录下的脚本。
而下面这个 init 脚本的作用是挂载上述 share 文件夹，并且在用户目录下建立可读写的 upload 文件夹
编写 init.sh

```bash
mkdir sftp.d
vim sftp.d/init.sh
```

文件内容如下

```bash
#!/bin/bash

function bindmount() {
    if [ -d "$1" ]; then
        mkdir -p "$2"
    fi
    mount --bind $3 "$1" "$2"
}

for user_home in /home/* ; do
  if [ -d "$user_home" ]; then
    username=`basename $user_home`

    echo "Setup $user_home/upload folder for $username upload files"
    mkdir -p $user_home/upload
    chown -R $username:users $user_home/upload

    echo "Setup $user_home/share folder for all user"
    bindmount /share/ $user_home/share
  fi
done
```

在创建完成后需要给 sftp.d/init.sh 增加执行权限

```
sudo chmod a+x sftp.d/init.sh
```

### 编写启动脚本

```
vim run.sh
```

内容如下：

```bash
#!/bin/bash
# after change users.conf, you should rerun this script
docker stop sftpd | grep -v "No such container: sftpd"
docker rm sftpd | grep -v "No such container: sftpd"
docker run \
    -v `pwd`/users.conf:/etc/sftp/users.conf:ro \
    -v `pwd`/ftpdata:/home \
    -v `pwd`/share:/share \
    -v `pwd`/sftp.d:/etc/sftp.d \
    --cap-add=SYS_ADMIN \
    -p 2222:22 \
    --name sftpd \
    --restart=always \
    -d atmoz/sftp
```

在创建完成后需要给 run.sh 增加执行权限，然后运行脚本

```
sudo chmod a+x run.sh
./run.sh
```

运行完脚本后会在当前目录新建 ftpdata 目录，该目录是用于存放用户文件，每个用户会在该目录下有个同名文件夹。保存备份数据也只需要复制该文件夹即可。
当在对 users.conf 文件做修改后（如添加删除用户，更换密码），需要再次执行 run.sh 脚本以生效。

### 编写停止脚本 stop.sh

```bash
#!/bin/bash
docker stop sftpd | grep -v "No such container: sftpd"
```

同样该脚本需要添加执行权限，在需要关闭 SFTP 服务时执行该脚本。

## 使用 SFTP 客户端进行检验

我这里常用的 FileZilla 客户端配置如下图
![filezilla sftp config](http://ws2.sinaimg.cn/large/9a1da786gy1g0769epta6j20kd0jzta3.jpg)

同时，让运维同学开启了 OwnCloud 的 SFTP 外部存储服务，个人配置如下图
![OwnCloud sftp config](http://ws2.sinaimg.cn/large/9a1da786gy1g076bkqnwsj21g2097wfd.jpg)

最终一个运行中的服务目录结构如下图：
![directory tree](http://wx4.sinaimg.cn/large/9a1da786gy1g076e7qhxpj20d10huwf7.jpg)
每个用户可以在自己的 upload 文件夹下进行上传文件，而 share 文件夹内的内容所有用户都能下载（我在这放了一个 Readme 让所有用户可以看到简单的使用方法），但不能上传。

这样我就可以使用 OwnCloud 里的分享等功能来进行视频的分享，同时也不需要运维同学担心磁盘的问题了（让他在另一台机器上部署了这个 SFTP 的 docker 服务）
