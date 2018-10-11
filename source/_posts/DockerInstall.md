---
title: ubuntu 17.04下安装docker国内镜像教程
date: 2017-04-18 01:06:23
tags:
    - docker
categories:
    - [运维]
---
前几天看到新闻说ubuntu以后要回归默认gnome，于是就在虚拟机下安装了新版的ubuntu-gnome17.04。顺手就总结下在纯净的ubuntu下安装docker的过程。

## apt源安装docker
自从ubuntu不知道哪个版本开始，就在apt源里自带docker了，不过不叫docker，名字叫docker.io。（注意：docker这个名字也对应着一个包，但不是我们要装的东西~）

所以如果想要默认安装，请直接运行`sudo apt-get install docker.io -y` 就可以了。


## 配置国内加速镜像
docker安装完成后，我们关键的还是需要配置一个国内的镜像源，不然每次拉取(pull)镜像的过程是相当漫长的。对此我们可以选择aliyun或者daocloud等国内公司。这里以aliyun为例子：

你需要在aliyun上注册一个账号，然后访问`https://cr.console.aliyun.com/#/accelerator`地址，上面会有你的加速地址，以替换下述命令中的网址。
```bash
# setting aliyun source
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://your.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 测试docker命令
我们可以使用`sudo docker run hello-world`来测试下docker的安装情况，若一切正常，会显示

![hello_world](docker-hello-world.png)

这时docker的安装就完成了，但如果你是一个像我一样的懒虫，这些可能还不够， 你发现在使用docker的时候需要不断的输入sudo，并提供密码之类的， 那是否有办法可以不输入sudo，以当前用户来完成docker的操作呢?

答案是肯定的~
## 免sudo运行docker命令
经过一番搜索，我们发现了其实运行docker指令就是和docker的进程进行通信， 而通信过程中使用的是socket文件，查看该socket文件，我们发现该socket文件的权限有点特别:

![docker-socket](docker-socket.png)

它是属于**root用户**和**docker组**的，这个docker组是什么呢?
查找了下文档，我们发现[docker官方文档](https://docs.docker.com/engine/installation/linux/linux-postinstall/)里就有这样一段话，并解决了我们的问题：
> The docker daemon binds to a Unix socket instead of a TCP port. By default that Unix socket is owned by the user root and other users can only access it using sudo. The docker daemon always runs as the root user.
> 
> If you don’t want to use sudo when you use the docker command, create a Unix group called docker and add users to it. When the docker daemon starts, it makes the ownership of the Unix socket read/writable by the docker group.

因此，参照文档中的做法，运行如下命令：
```bash
sudo groupadd docker
sudo usermode -aG docker $USER
sudo groups $USER  # check which groups I joined.
## username : group1 group2 .... docker  # expected output
```
然后注销用户，再次登录后即可（我是直接重启~ 虚拟机丢那自己动图方便）
至此，我们就完成了docker在ubuntu-gnome17.04上的安装。

