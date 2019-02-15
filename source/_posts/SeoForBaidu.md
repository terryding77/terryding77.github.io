---
title: 使用gitlab的pages功能让百度收录github博客
date: 2017-04-18 11:22:04
tags:
  - seo
  - baidu
  - gitlab
  - dns
  - travis-ci
categories:
  - [SEO]
---

今天给博客添加了 baidu 和 google 的校验文件，希望能让搜索引擎快速的收录博客的变更，但是操作中发现 baidu 的爬虫没办法爬去博客的 sitemap

![baidu-fetch-site-error](http://wx1.sinaimg.cn/large/9a1da786gy1g06ws0j13sj20y90cqq4i.jpg)

于是搜了下这个问题，发现有人向 github 提出了这个问题，github 的回答是将百度的爬虫给屏蔽了。。。

那对于这样的问题我就很无奈了，有人说用 cdn，有人说用对百度爬虫另开一台服务器，专门给它爬。(前提是你的博客是绑定了自己域名的)

我就想能不能综合下这两个想法呢?

本身 github 的博客部署的是静态文件，那静态文件部署在另一个地方应当也可以，就像大家说的给百度爬虫另开一台服务器，但我并不想自己搭建服务器给博客，感觉还是有点负担。看到人家说不要用 github，转用 gitcafe，我想那我能不能部署两个 pages 呢，我习惯用 github，同时也部署在另一个百度爬虫可以访问的 pages 服务，这样我一旦部署完成，整个网站都不用我管理什么了。

我以前用过 oschina 的码云，搜了下，现在码云也支持 pages 了，但是经过一番测试后发现可以搭建博客但是不支持自定义域名，在一番寻找之后选择了 gitlab。

# gitlab pages 使用

## gitlab 账户注册

[gitlab](https://gitlab.com/)可以使用 github 账户直接登录，重新校验一下邮箱并设置下密码即可

## 创建 yourname.gitlab.io 项目

![gitlab-new-project](http://wx3.sinaimg.cn/large/9a1da786gy1g06wrzzo5pj21ev0najto.jpg)

## 添加两个文件 index.html 和.gitlab-ci.yml

内容如下:

```bash
$ cat index.html

hello world!

$ cat .gitlab-ci.yml

pages:
  stage: deploy
  script:
  - mkdir .public
  - cp -r * .public
  - mv .public public
  artifacts:
    paths:
    - public
  only:
  - master
```

完成修改后 push 到 gitlab 上，这时会触发 gitlab 的 ci
![gitlab-ci](http://wx1.sinaimg.cn/large/9a1da786gy1g06ws06l1aj21go0lvgpb.jpg)

## 最后访问[http://yourname.gitlab.io](http://terryding77.gitlab.io/)

![visit-oschina-pages](https://ws4.sinaimg.cn/large/9a1da786gy1g06wrxz2pgj20cc02xq2u.jpg)

这时 gitlab 的 pages 服务就配置完成了，以后在博客变动后向对 github 提交一样，使用 git 向 gitlab 提交你的修改就行

## 自定义域名

可能我们有自己的域名想绑定到 gitlab pages，这时可以在项目的 pages 选项里进行添加，选择 settings-pages-new domain，输入你自己的域名(https 请提供相关文件)，然后就能看到提示你可以使用该域名访问了。
![gitlab-page-custom-website](https://wx3.sinaimg.cn/large/9a1da786gy1g06wrzthh0j21cf0esq44.jpg)

# 给百度爬虫专用 dns

我的域名是使用阿里云的域名解析，在这里我需要在原本 github.io 的解析之外添加一条百度专线的 cname
![aliyun-dns-for-baidu](https://wx1.sinaimg.cn/large/9a1da786gy1g06ws0omtqj218i06xq3v.jpg)
如果你觉得 gitlab 的解析更方便，你可以将 gitlab 的解析线路改为默认，github 的解析线路改成海外。

# 自动化 gitlab page 的部署

虽然上面的方法解决了百度爬虫爬取的问题，但是我还是觉得比较麻烦，每次都要单独向 gitlab 推送下更新，我能不能将这一操作自动化呢?

我在之前就使用 travis-ci 来自动化部署我 github 上提交的 hexo 代码，自动生成站点静态文件并提交到 github 的 master 分支上。
自动化部署 github pages 博客请参见

1. [使用 Travis CI 自动更新 GitHub Pages](http://notes.iissnan.com/2016/publishing-github-pages-with-travis-ci/)
1. [使用 Travis CI 自动更新 Hexo Blog](http://xwartz.xyz/pupa/2016/06/auto-update-with-travis-ci/)

现在我希望的是在 travis-ci 里添加向 gitlab 自动 push 的代码。

## 申请 gitlab 的 access token

在 gitlab 的个人设置页面找到 access token 并如下填写各项内容，然后会生成一个 token 字符串，复制它备用。
![gitlab-access-token](https://wx3.sinaimg.cn/large/9a1da786gy1g06ws0cmiwj21180g4dgz.jpg)

## 将 gitlab 的 access token 加入 travis-ci 的环境变量

登陆[travis-ci.org](https://travis-ci.org)并在项目设置中添加 gitlab token 的环境变量
![travis-ci-add-gitlab-token](https://ws1.sinaimg.cn/large/9a1da786gy1g06wryk0g8j215v0983z2.jpg)

## 取消 gitlab 的 master 分支 force push 保护

由于我们要在 ci 中强制把生成的站点文件 push 到 gitlab，需要将 gitlab 对应的 master 分支解除保护

选择项目的 settings-repository 下的 protected branchs 将 master 从中删除
![gitlab-unprotect-branch](https://wx2.sinaimg.cn/large/9a1da786gy1g06wrzjdhwj21f50m9gox.jpg)

## 添加.gitlab-ci.yml 并修改.travis-ci.yml 文件

- 将之前在 gitlab 中使用的.gitlab-ci.yml 添加至 git 仓库
- 修改.travis-ci.yml 文件，增加 gitlab 分支的 push 部分(after_script 的最后两行 以及 env 下的 GL_REF 变量)

```yaml
language: node_js
node_js: lts/*

# S: Build Lifecycle
install:
  - npm install

script:
  - cp material_theme_config.yml  themes/hexo-theme-material/_config.yml
  - hexo g

after_script:
  - cd ./public
  - git init
  - git config user.name "terryding77"
  - git config user.email "terryding77@gmail.com"
  - git add .
  - git commit -m "Update docs"
  - git push --force --quiet "https://${GITHUB_TOKEN}@${GH_REF}" master:master
  - cp ../.gitlab-ci.yml ./ && git add .gitlab-ci.yml && git commit -m "add ci file"
  - git push --force --quiet "https://oauth2:${GITLAB_TOKEN}@${GL_REF}" master:master
# E: Build LifeCycle

branches:
  only:
    - blog-source

env:
  global:
    - GH_REF: github.com/terryding77/terryding77.github.io.git
    - GL_REF: gitlab.com/terryding77/terryding77.gitlab.io.git
```

在完成修改后将代码 push 到 github 上，然后就等待 travis-ci 和 gitlab-ci 完成部署即可~
