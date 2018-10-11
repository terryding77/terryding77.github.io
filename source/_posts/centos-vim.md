---
title: 拷贝个人命令行相关配置到服务器中
date: 2018-07-17 14:21:30
tags:
    - centos
    - vim
categories:
    - [运维]

---
如何快速的将我本地运行的环境转移到一台新安装的服务器环境呢？
可以省略一些代码补全插件，但是常用的一些显示优化，操作简化的插件还是需要可使用

**打包并上传本地安装文件夹**

由于我的仓库 [dotfiles](https://github.com/terryding77/dotfiles) 中不只包含了vim，还有zsh、tmux等设置，我将其一并打包和安装。
`tar -zcvf dot.tar.gz dotfiles`， 而后`scp dot.tar.gz username@server_ip:/path/to/receive`

**解压并安装依赖**

```bash
sudo yum -y install epel-release
sudo yum install -y zsh gcc python34 ncurses-devel wget unzip lua-devel python-devel perl-devel ruby-devel python34-pip python34-devel cscope words tmux git
tar zxvf dot.tar.gz
cd dotfiles/
cd zsh && zsh Install.sh && cd ..
cd vim && zsh Install.sh && cd ..
cd python && zsh Install.sh && cd ..
cd ..
wget https://github.com/vim/vim/archive/master.zip
unzip master.zip
cd vim-master/src
./configure \
    --enable-gnome-check \
    --enable-gtk2-check \
    --enable-multibyte \
    --enable-python3interp \
    --enable-rubyinterp \
    --with-compiledby="Terry Ding <terryding77@gmail.com>" \
    --with-python3-config-dir=/usr/lib64/python3.4/config-3.4m \
    --enable-cscope \
    --enable-gui=auto \
    --with-features=huge \
    --with-x \
    --enable-fontset \
    --enable-largefile \
    --disable-netbeans \
    --enable-fail-if-missing
make && sudo make install
cd ../..
sudo pip3 install neovim
```
至此 算是基本可以开始使用该vim+zsh 的环境了
有些细节问题可以通过去除部分插件进行修正，如删除zshrc中的nvm插件可以不用在初次进入zsh中等待下载nvm

