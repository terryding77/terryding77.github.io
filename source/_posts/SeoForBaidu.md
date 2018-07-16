---
title: 使用gitlab的pages功能让百度收录github博客
date: 2017-04-18 11:22:04
tags: [seo, baidu, gitlab, dns, travis-ci]
---
今天给博客添加了baidu和google的校验文件，希望能让搜索引擎快速的收录博客的变更，但是操作中发现baidu的爬虫没办法爬去博客的sitemap

![baidu-fetch-site-error](baidu-fetch-site-error.png)

于是搜了下这个问题，发现有人向github提出了这个问题，github的回答是将百度的爬虫给屏蔽了。。。

那对于这样的问题我就很无奈了，有人说用cdn，有人说用对百度爬虫另开一台服务器，专门给它爬。(前提是你的博客是绑定了自己域名的)

我就想能不能综合下这两个想法呢?

本身github的博客部署的是静态文件，那静态文件部署在另一个地方应当也可以，就像大家说的给百度爬虫另开一台服务器，但我并不想自己搭建服务器给博客，感觉还是有点负担。看到人家说不要用github，转用gitcafe，我想那我能不能部署两个pages呢，我习惯用github，同时也部署在另一个百度爬虫可以访问的pages服务，这样我一旦部署完成，整个网站都不用我管理什么了。

我以前用过oschina的码云，搜了下，现在码云也支持pages了，但是经过一番测试后发现可以搭建博客但是不支持自定义域名，在一番寻找之后选择了gitlab。

# gitlab pages 使用

## gitlab账户注册
[gitlab](https://gitlab.com/)可以使用github账户直接登录，重新校验一下邮箱并设置下密码即可

## 创建yourname.gitlab.io项目
![gitlab-new-project](gitlab-new-project.png)
## 添加两个文件index.html和.gitlab-ci.yml
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
完成修改后push到gitlab上，这时会触发gitlab的ci
![gitlab-ci](gitlab-ci.png)

## 最后访问[http://yourname.gitlab.io](http://terryding77.gitlab.io/)
![visit-oschina-pages](visit-oschina-pages.png)

这时gitlab的pages服务就配置完成了，以后在博客变动后向对github提交一样，使用git向gitlab提交你的修改就行

## 自定义域名
可能我们有自己的域名想绑定到gitlab pages，这时可以在项目的pages选项里进行添加，选择settings-pages-new domain，输入你自己的域名(https请提供相关文件)，然后就能看到提示你可以使用该域名访问了。
![gitlab-page-custom-website](gitlab-page-custom-website.png)


# 给百度爬虫专用dns
我的域名是使用阿里云的域名解析，在这里我需要在原本github.io的解析之外添加一条百度专线的cname
![aliyun-dns-for-baidu](aliyun-dns-for-baidu.png)
如果你觉得gitlab的解析更方便，你可以将gitlab的解析线路改为默认，github的解析线路改成海外。

# 自动化gitlab page的部署
虽然上面的方法解决了百度爬虫爬取的问题，但是我还是觉得比较麻烦，每次都要单独向gitlab推送下更新，我能不能将这一操作自动化呢?

我在之前就使用travis-ci来自动化部署我github上提交的hexo代码，自动生成站点静态文件并提交到github的master分支上。
自动化部署github pages博客请参见
1. [使用 Travis CI 自动更新 GitHub Pages](http://notes.iissnan.com/2016/publishing-github-pages-with-travis-ci/)
1. [使用 Travis CI 自动更新 Hexo Blog](http://xwartz.xyz/pupa/2016/06/auto-update-with-travis-ci/)

现在我希望的是在travis-ci里添加向gitlab自动push的代码。

## 申请gitlab的access token
在gitlab的个人设置页面找到access token并如下填写各项内容，然后会生成一个token字符串，复制它备用。
![gitlab-access-token](gitlab-access-token.png)


## 将gitlab的access token加入travis-ci的环境变量
登陆[travis-ci.org](https://travis-ci.org)并在项目设置中添加gitlab token的环境变量
![travis-ci-add-gitlab-token](travis-ci-add-gitlab-token.png)

## 取消gitlab的master分支force push保护
由于我们要在ci中强制把生成的站点文件push到gitlab，需要将gitlab对应的master分支解除保护

选择项目的settings-repository下的protected branchs将master从中删除
![gitlab-unprotect-branch](gitlab-unprotect-branch.png)

## 添加.gitlab-ci.yml并修改.travis-ci.yml文件
- 将之前在gitlab中使用的.gitlab-ci.yml添加至git仓库
- 修改.travis-ci.yml文件，增加gitlab分支的push部分(after_script的最后两行 以及 env下的GL_REF变量)

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
在完成修改后将代码push到github上，然后就等待travis-ci和gitlab-ci完成部署即可~

