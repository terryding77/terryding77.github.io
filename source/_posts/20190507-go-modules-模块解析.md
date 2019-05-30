---
title: go modules 模块解析
tags:
  - Golang
categories:
  - [Golang, Modules]
  - [翻译]
abbrlink: 9c8bdfe5
date: 2019-05-07 16:20:13
---

> 原文：[Anatomy of Modules in Go](https://medium.com/rungo/anatomy-of-modules-in-go-c8274d215c16)

# 摘要

Modules 是 Go 语言项目中一个新的管理依赖的方案。Modules 允许我们在项目中可靠的使用同一个依赖的不同版本。

> 在阅读本文之前，请注意 Modules 是从 Go 1.11 开始被支持，并将在 Go 1.13 的版本中被真正完善。所以当在使用 Go 1.13 以下的版本时，其实现可能会在未来有所调整。（译者：当前稳定版为 Go 1.12.5, Go 1.13 预计应当在 2019 年 8 月左右会发布）

# 历史问题

## 强制使用 GOPATH

回顾下在没有 Go Modules 的时候的大家的工作环境。当我们有需求去编写 Go 语言的代码时，需要将代码放置于**`$GOPATH`**的路径下（这就是我们的 Go workspace 工作区）。当我们使用命令`go get`去安装依赖包(译者：以下所有包都对应着 go 的 package 概念，不再单独指出，而项目需要使用的非本项目的 package 则称为依赖包)的时候，依赖包的代码将会被存入`$GOPATH`目录下。只有当依赖包的代码被存入`$GOPATH` 后，我们编写的代码才能够成功地引用它。同时当我们使用`go build`命令创建代码相应的二进制文件时，也将会存储在`$GOPATH`内。所以说，这个时期的`$GOPATH`是 Go 中非常重要的一个概念。
而很多情况下用户还是无法接受这种强制要求将所有项目放在固定目录的设定。

## 无法使用同一依赖包的多个版本

由于`go get`会将依赖包不同版本的代码放入同一个目录（因为目录名称就是依赖包的包名）所以我们也无法在项目中使用同一个依赖包的不同版本。如果我们真的需要在 `GOPATH` 之外进行开发，那么我们需要相应的修改**`GOPATH`**的环境变量，当我们改动了`GOPATH`后，之前所安装的依赖包也需要从原本的`GOPATH`中将代码拷贝过来或者重新使用`go get`进行安装。

## 没有中心化的包管理源

有一个有趣的事实，Go 语言并没有提供软件中心给用户下载依赖包，如果你是 node.js 的开发者，你会很熟悉 npm 仓库，它给用户提供了下载和发布 node.js 模块的功能，而这样的功能在 Go 中又是如何完成的呢？

通常，引用一个第三方的 Go 依赖包需要在代码中写上如下的声明:

```golang
import "github.com/username/packagename"
```

如果仔细关注这段代码，你会发现依赖包的名称看起来很像 URL，不好意思，它就是 URL。Go 可以下载和安装互联网上任何网站的 Go 包，如果你想安装上述的依赖包，你可以用如下的`go get`命令：

```shell
go get github.com/username/packagename
```

如果`https://github.com/username/packagename`这个 URL 可以被正确的解析，Go 就会访问它并下载包的代码。当下载完成后，其中的文件会被存放于`$GOPATH/src/github.com/username/packagename`的路径下。注意，Go 标准库包的代码则是放在`$GOROOT`目录下（当 Go 环境安装完成时就已经存放在此）。而我们普通用户的各个包的代码都会储存在`$GOPATH`内。

> 对比 npm，npm 会将依赖包存放在本项目的目录下（项目下的 node_modules 目录），并不像`$GOPATH`那样存在统一的位置（但也不能像`$GOPATH`那样可以被重新设置）。在 npm 中，我们有`package.json`文件（同`package-lock.json`文件一起）将当前项目所安装的依赖包及版本精确的以文本形式记录下来。

# `go get`工作流程

接下来让我们来理解下`go get`是如何工作，而我们需要如何维护自己的 Go 包。首先像上面安装包那样运行下面的指令：

```shell
go get domain.com/path/to/sub/directory
```

此时 Go 会先尝试以安全的**HTTPS**协议来访问网站`domain.com/path/to/sub/directory`。如果这个 URL 不支持**HTTPS**或者返回 SSL 错误，同时`GIT_ALLOW_PROTOCOL` 环境变量中包含**HTTP**协议，那么 GO 就会退而求其次的尝试用**HTTP**协议来解析这个 URL。

网络上的 Go 包应当是使用像**GIT**或者**SVN**这样的**（VCS）**进行版本管理的代码仓库，以下这些版本管理系统（VCS）是被支持的：

```
- Bazaar     .bzr
- Fossil     .fossil
- Git        .git
- Mercurial  .hg
- Subversion .svn
```

如果 domain.com 是一家 Go 支持的知名代码托管网站，那么 Go 会先尝试解析`domain.com/path/to/sub/directory.{type}`，其中 type 可以是`git hg` 等指定类型。下面是 Go 支持的代码托管网站及相应的 type 类型。

```
- Bitbucket           (bitbucket.org) .git/.hg
- GitHub              (github.com)    .git
- Launchpad           (launchpad.net) .bzr
- IBM DevOps Services (hub.jazz.net)  .git
```

当一个版本管理系统支持多种协议时，Go 会依次尝试使用每种协议来解析 URL。比如 Git 就支持 https 协议和 git+ssh 协议，这些协议会被 Go 依次尝试。

如果 Go 成功的解析了上面的 URL，就会使用相应的工具（如 git）进行克隆并存储于之前我们分析的`$GOPATH/src`下的对应目录。

但是如果该包的 URL 并不是 Go 支持的代码托管网站，Go 就没有办法立刻确定对应的版本管理系统。这种情况下 Go 会试着用上面我们说的支持的版本管理系统来解析 URL，如果 URL 被成功解析并返回**HTML 文档**，Go 会查找文档内如下的特殊**meta tag**：

```html
<meta name="go-import" content="import-prefix type repo-root" />
```

> 注意：为了避免出现解析错误，这条**meta tag**应当尽可能放在 HTML 文件的开始部分

让我们简单解析下这条 meta tag

- import-prefix: 这是包被 import 时的路径，在我们的例子里它应该是 domain.com/path/to/sub/directory
- type: This is the type of your VCS repository. It can be one of the supported types mentioned earlier. In our case, it could be a Git repository, hence git type.
- type: 这是该包对应的版本管理系统（VCS）类型，它应当是我们之前提到的受 Go 支持的类型之一。在我们的例子里它应该是 git
- repo-root: 这是版本管理系统下该包的代码仓库的 URL，例如在我们的例子里，它可以是 https://domain.com/repos/name.git 这个 git 后缀是可选的，因为我们在之前的 type 中已经提到了它是 git 类型

使用这个 meta 信息，Go 就能够在 `https://domain.com/repos/name.git`里使用 git 命令行工具克隆仓库并把代码存入`$GOPATH/src/domain/path/to/sub/directory`目录下了。

如果`import-prefix`的值不同于`go get`命令里的 URL，Go 会选择将代码放入**import-prefix**对应的目录。例如使用下面这条`go get`命令：

```shell
go get domain.com/some/sub/directory
```

Go 会访问`https://domain.com/some/sub/directory`, 如果站点返回的 HTML 文档内容中是以下的 meta tag：

```html
<meta
  name="go-import"
  content="domain.com/someother/sub/directory git https://domain.com/repos/name.git"
/>
```

由于**import-prefix 与`go get`命令里的 URL 不同**，Go 会验证是否`domain.com/someother/sub/directory`也返回同样的 meta tag，然后包会被安装在`$GOPATH/src/domain.com/someother/sub/directory`目录下，依赖该包的 Go 文件需要添加如下声明语句：

```Golang
import "domain.com/someother/sub/directory"
```

# 向后不兼容难题

目前为止，我们已经对 Go 以往进行包管理的方案有了足够的了解，让我们看看这样的方案在包**不向后兼容**时会产生怎样的问题。

假定位于`github.com/thatisuday/stringmanip`是一个支持 string 字符串处理的包（比如将 string 中的字符转成大写之类）。当用户使用`go get`进行下载时，会**克隆该包代码仓库 master 分支的最新 commit 提交版本。**

这时突然一个新的 commit 提交改变了某个函数的实现，加入了一些与之前代码不兼容的修改，或是创建了一些 bug。此时当用户更新或者重新安装该包，依赖该包的代码就会由于这些变动而导致无法运行。

我们没有办法使用`go get`指定克隆 git 仓库的**特定 commit 或者是 tag**。这也表示我们**无法下载包的指定版本**。同时由于 Go 将包下载到以其包名命名的目录，我们也**无法同时存储一个包的多个版本**。这是种非常粗暴的包关系处理方案，而现在**Go Modules**将来解决这个问题。

# Go Modules 教程

## 设计要求

让我们首先理解下`Go Modules`的原理。对比我们讨论过的 Go 原本的包管理方案，很容易想到下面几点改进：

- 首先，我们应当可以在任何目录下工作，而不是仅仅在`$GOPATH`下。这可以让我们灵活的按个人需求放置源代码。
- 其次，我们应当可以安装某个依赖包的历史版本，以保证可以避免遭遇更新而导致的不向后兼容的问题。
- 然后，我们应当可以引用一个依赖包的多个版本。这在我们的旧应用代码还在依赖着旧版依赖包持续运行，而我们想使用新版依赖包进行一些新的开发时非常有用。
- 最后，类似 npm 的`package.json`，我们需要在项目里有一个文件来记录这些依赖包。当我们在分发项目时，我们就不需要同时把这些依赖包的代码一起发送出去，Go 可以对照这个文件然后帮我们下载所需要的依赖包。

好消息是，`Go Modules`能够实现我们上面的所有要求，并且做的更好。`Go Modules`给我们提供了原生的依赖管理系统。让我们来理解这个新概念“**模块（module）**”的定义，一个模块是指一个包含 Go 包的目录，它可以是分发包（distribution package）也可以是可执行包（executable package）。(译者：个人认为想表达的是模块既可以是一个可以直接产生二进制文件执行的包，也可以是提供给其他包各类工具函数作为依赖的包)

一个模块也可以像包一样与别人共享。因此，它必须使用 Git 或者其他 VCS 版本管理系统进行管理，例如托管在 Github 这样的平台，Go 推荐：

- 一个 Go 模块必须是一个代码仓库，或者某个代码仓库中包含一个独立的 Go 模块
- 一个 Go 模块应当包含一个到多个包
- 一个包应当在单独的目录下包含一到多个`.go`文件

## 创建 Go Module 模块

看完了理论，让我们用代码尝试一些操作。首先创建一个空目录，不要放在`$GOPATH`下。我现在使用`nummanip`目录来存放我的 Go 模块，这个目录下将存放一些包以及处理`number`这个数据结构。
![新建仓库目录](http://wx1.sinaimg.cn/large/9a1da786gy1g2ttbk2w6aj212w0avju9.jpg)

正如我们之前提到的`Go Modules`需要一个代码仓库，我们在 Github 上使用以下这个[URL](https://github.com/thatisuday/nummanip)创建一个 Git 代码仓库。
![创建Github仓库](http://ws4.sinaimg.cn/large/9a1da786gy1g2ttdyab1vj212w0e3q6m.jpg)

接下来我们需要在该目录初始化`Go Modules`。使用`go mod init`命令来创建`go.mod`文件（类似 npm 的`package.json`文件），文件中会包含模块对应的引用路径和模块会使用的依赖包。我们也要初始化 Git 代码仓库，将目录与远端的 Github 仓库建立联系。
![初始化Git和Go-Modules](http://ws4.sinaimg.cn/large/9a1da786gy1g2ttj9rddgj20m808hdhv.jpg)

```shell
mkdir nummanip && cd nummanip
git init
git remote add origin https://github.com/thatisuday/nummanip.git
go mod init github.com/thatisuday/nummanip
```

> 注： 默认情况下在`$GOPATH`内创建模块是被禁止的，会返回`go: modules disabled inside GOPATH/src by GO111MODULE=auto; see 'go help modules'`的错误。这也是在为后期废弃`$GOPATH`做的预防措施。如果真的有这方面的需求，可以将`GO111MODULE`这个环境变量设为`on`。

创建的`go.mod`文件包含模块引用路径和模块创建时 Go 的版本（译者：当前都为 Go 1.12，在 Go1.11 早期版本时`go init`命令不会写入 go 的版本信息）。前面这些复杂的准备工作完成后，我们就能开始我们编写模块内各个包的代码了。
![模块包目录](http://wx1.sinaimg.cn/large/9a1da786gy1g2ttt71upbj20m80aadh4.jpg)

我们在模块内创建了两个包。现在它们还是空的目录，接下来我们放入一些代码。`calc`包将提供 number 之间的计算方法，而`transform`包则提供 numer 相关的数据结构类型转换的功能。

> 当我们在模块中编写多个包的时候，我们需要给它们每个都创建一个文件夹。但如果只想提供一个单独的包，我们就不需要在当前文件夹下再新建一级，直接将包的代码文件放在模块路径（`go.mod`文件所在的路径）下。仅在我们引用这些包时会有些区别，我们稍后会谈到这些。

## 创建本地模块

到了这一步，我们并没完全决定我们的模块是一个可执行应用还是给大家提供各种工具的 library 库。我非常推荐大家将自己代码中可重复利用的逻辑抽象成独立的包并且在应用中引用它们。所以为了测试我们的模块和包，我们再创建另一个模块来使用`nummanip`模块，这个用来测试的模块我并不想不发布到网络上，此时我们可以使用一个**非 URL**的模块名来初始化它。

> Go 提供了`go test`工具帮助我们使用第三方测试组件来测试我们的代码，这和我们接下来的教程并不是同一个话题。

![local-Modules本地模块](http://ws3.sinaimg.cn/large/9a1da786gy1g2tuapaz1fj20m80bm0tx.jpg)

我们为了测试使用`go mod init main`命令创建了`main`模块。为了方便，我们在 VSCode 工作区里同时打开了`main`和`nummanip`两个模块的目录。
![vscode同时打开main和nummanip两个目录](http://ws2.sinaimg.cn/large/9a1da786gy1g2tucxr524j20m80bmdh8.jpg)

我们在`calc`包里编写了`math.go`文件来提供`Add`工具函数用于**返回两个数字之和**。注意包的申明部分，`package calc`标识了`math.go`这个文件属于`calc`包，而由于本包是在模块内独立的文件夹`calc`中的，所以**这段包名称的申明与模块名称是没有关系的**。

> 如果我们的包代码直接是放于模块目录下，那包名就应当和模块的名称相同（为了保证在`import`引用时可以正确的解析)

## 提交模块的首个版本

接下来让我们尝试发布模块。发布模块其实就是简单的将代码推向远端仓库的指定 tag 分支。在我们做之前，先理解两个概念**语义化版本号**和**git tags**。

### 语义化版本号

语义化版本号（`Semantic Versioning` 或 `SemVer`）是一个被广泛接受的标记发布的模块或者包的方案。它通常用 `vX.Y.Z`的格式表示，其中**X**表示主要（major）版本，**Y**表示次要（minor）版本，**Z**表示补丁（patch）版本。例如一个包的版本是`1.2.0`，就表示它主要版本是 1，次要版本是 2，补丁版本是 0,。我们会在包仅有小修改时增加补丁版本，当新功能或者性能提升时增加次要版本，当与旧版本之间产生很大的变更时，我们提升主要版本。提升主要版本时，次要版本和补丁版本都重置为 0（比如`2.0.0`）

> 额外的`预发布版本`可以通过增加后缀的方式表达，例如`x.y.z-rc.0`表示一个预发布序号为 0 的版本（或者`x.y.z-beta.1`）。这对一些需要测试预发布版本的软件很有帮助。

Go 指定了，当新旧版本之间不兼容时，新版本应当进行主要版本号的更新。**当新的主要版本(例如 V2.0.0)发布时，Go 会将其当做一个不同的模块来对待**，这点很重要，后面我们会演示。

我们知道，Git 的分支其实就是一系列提交历史的集合。每个提交有自己唯一的识别码（commit hash）。在某个特定的提交版本我们可以知道仓库中文件的状态。当发布代码时，我们需要同时提供当前的 commit hash 来保证用户在他们的生产环境使用这些代码时，代码是处于此 commit hash 状态稳定不会变动的。另一种方法就是给这个 commit hash 起一个别名，例如 SemVer 语义化版本号，这种方案可以称为打标签[tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

Git 提供了两种打标签的方法，**Lightweight Tag**这种是简单的指向 Git 历史中的一次提交。而**Annotated Tag**则是保持了 Git 自身数据库中的所有对象（包括一些额外信息，如打标签的用户姓名，标签信息和其他等等）。关于**Annotated Tag**你可以阅读这里的[详细资料](https://git-scm.com/book/en/v2/Git-Basics-Tagging)，我们将使用**Lightweight tag**的方式打标签。

这是我们第一次发布此模块，我们需要创建一个提交并将其推送到远端。然后我们对刚刚的提交使用语义化版本号的形式打上标签。

![提交代码](http://ws2.sinaimg.cn/large/9a1da786gy1g2tw4dxcguj20m80bmmzb.jpg)

上图就是完成提交和推送的过程（译者：如读者跟随教程一起实验，请在 push 前执行`git add .` 和`git commit -m"xxx"`操作），`-f`参数强制推送这在第一次提交时是没问题的，接下来打标签。

![打标签](http://ws1.sinaimg.cn/large/9a1da786gy1g2tw9xj2irj20m80bmdhr.jpg)

我们首次发布版本，可以用`v1.0.0`的语义化版本号。当我们发布`Go Modules`模块的时候，我们的语义化版本号标签名必须是以小写的**v**开头。在创建完 git 标签后，我们需要使用`git push --tags`命令推送到远端仓库。
![GitHub provides information about tag inside the Releases section.](http://wx3.sinaimg.cn/large/9a1da786gy1g2twd7ofbtj20m8062gm5.jpg)

![运行main模块](http://wx1.sinaimg.cn/large/9a1da786gy1g2twdnw9xgj20m80do0uu.jpg)
接下来我们在`main`模块内创建`app.go`文件来测试是否版本发布生效。我们从`github.com/thatisuday/nummanip`模块中引用`calc`包，并调用它的`Add`方法。由于我们既知道模块路径又知道包名，我们可以直接 import 引用包的完整 URL 路径。

> 如果我们的包代码是直接写在模块目录下的，我们可以只 import 引用`github.com/thatisuday/nummanip`并使用`nummanip`作为包名去执行`nummanip.Add()`函数

注意，到现在为止我们还并没有使用`go get`命令来安装这个模块。确实我们可以通过`go get`来安装它。但其实当我们尝试使用`go run <file>`来运行`app.go`文件时，Go 会分析引用并自动请求最新版本`v1.x.x`（稍后再解释这点）的`nummanip`模块。当 Go 成功下载模块后，它会同时将下载的依赖模块信息更新记录到`go.mod`文件中。

> 这种方案能够帮助我们不需要告诉其他人需要安装什么什么依赖，Go 可以直接通过解析`go.mod`文件来处理模块所需的依赖。

![模块依赖](http://wx2.sinaimg.cn/large/9a1da786gy1g2tx3sghbrj20m80agabh.jpg)
(译者：图中 nummanip 版本为 v1.0.1 应该为 v1.0.0，此图可能是作者后期补充，版本号由于后面的操作而被修改过)

> 你可能会疑惑，Go 是如何解析 import 引用的 URL 的。例如`https://github.com/thatisuday/nummanip/calc`是会返回**404 Not Found**页面。关于这点，我也没能查到详细的文档，但是我猜测由于 Github 是 Go 可以识别的代码托管网站，Go 对其是有特殊的方案来定位包的位置，就像[这里](https://golang.org/cmd/go/#hdr-Remote_import_paths)所说的。

现在可能我们还有一些不解。Go 什么时候会自动安装依赖模块？`go get`还有什么用处？这些模块代码被储存到哪里去了？

`Go Modules`被存入`$GOPATH/pkg/mod`目录下（module 缓存路径）。看起来我们好像还是没有摆脱`$GOPATH`的魔掌。但是 Go 确实需要找个公共的目录以保证不会将同一个包的同一个版本重复下载。

而当我们执行`go run`命令或者`go test; go build`这样的 Go 命令时，Go 会自动的检查第三方 import 引用申明（类似我们这个模块里的引用），并且将依赖模块的代码仓库克隆到本地 module 缓存路径。
![GOPATH-pkg-mod](http://wx4.sinaimg.cn/large/9a1da786gy1g2txpeu6yxj20m80a30vp.jpg)

我们可以看到模块缓存路径中有`nummanip`模块，且是标记为`v1.0.0`版本时的代码。Go 同时创建了`go.sum`文件来保存**直接或间接被本模块引用的依赖模块的内容**的 checksums（类似 commit hash，用来检测文件内容是否更改，一旦更改此计算值也会变化）。

![go.sum file](http://ws3.sinaimg.cn/large/9a1da786gy1g2txwwwu1oj20m807hgmu.jpg)

npm 的`package-lock.json`文件是一个锁定文件，为了 100%重现编译过程而存储引用的依赖版本信息，而`go.sum`文件并不是用于锁定版本的文件，它应当和我们的代码一起提交到代码仓库中（[详细解释](https://github.com/golang/go/wiki/Modules#is-gosum-a-lock-file-why-does-gosum-include-information-for-module-versions-i-am-no-longer-using)）。不过当其他人使用此模块时`go.sum`通过记录每个模块的 checksums 也能给 100%重现编译环境有很重要的帮助。（译者：这段主要看下详细解释，我并没有完全理解两个文件之间的区别，感觉是说 go.sum 并不强制而 package-lock.json 是强制的）

## 升级 patch 补丁版本号并使用

接下来让我们添加些代码，为模块生成一个新的补丁版本。
![patch-version-1.0.1](http://ws4.sinaimg.cn/large/9a1da786gy1g2tyli8va4j20m80fadj9.jpg)

当我们修改`Add`函数的参数形式，通过[可变参数](https://medium.com/rungo/variadic-function-in-go-5d9b23f4c01a)的方案使其能够接受多个参数时，我们推送了一个新的标签`v1.0.1`。

让我们在`main`模块中使用新的`Add`函数。由于 Go 之前已经下载了`nummanip`模块，所以`go run`命令不会主动获取新版本的依赖模块。为了使用新版，我们需要手动更新我们的依赖模块（在最坏的情况下可能会需要重新安装）
![update go modules](http://ws3.sinaimg.cn/large/9a1da786gy1g2tysd8s91j20m80d8gnr.jpg)

为了更新当前已经存在于`go.mod`文件中的依赖模块，我们需要使用`go get -u`的命令。这条命令会更新所有的模块，将它们的次要版本或补丁版本提升到最新，但不会改变主要版本（后面将解释）。如果当新的次要版本出现后我们也只想更新 patch 补丁版本的话，可以使用`go get -u=patch`命令来实现。

如果需要使用某个依赖模块的某个精确的版本，我们需要使用`go get module@version`命令。例如在我们的例子里为了安装`v1.0.1`版本，我们应当使用`go get github.com/thatisuday/nummanip/calc@v1.0.1`命令来实现。（译者：原文用 1.1.2，感觉 1.0.1 更合适且读者可以立刻尝试此命令）

![Module cache after go get -u](http://ws4.sinaimg.cn/large/9a1da786gy1g2tz2rogppj20m80a3whf.jpg)

正如你所看见的，使用`go get -u`后 Go 下载了最新`v1.0.1`版本的模块并储存到缓存目录中。这样在公共基本的依赖管理方案就可以让系统里各种模块同时使用依赖模块不同的版本。

## 升级 Major 主要版本号并使用

现在是时候解释为什么使用`go get -u`命令升级依赖模块的版本时，Go 仅仅会处理`v1.x.x`这样的版本号了。

大家通常会有这样的共识，当某个软件有了相对很多的更新和修改后是需要升级软件的 major 主版本号的。例如**Angular v1**和**Angular v2**就有很多不同。同理，当某个依赖模块以特定的 major 主版本号的状态被 import 引用时，如果升级到新的 major 主版本号就可能会导致不兼容，让我们的一些代码无法正常工作。
那如果我们的应用可以在 major 大版本升级后正常的编译和运行的情况下，`go get -u`会升级 major 大版本号么，像`v1.0.2`到`v2.0.0`这样。Go 怎么处理这种需求呢？
在 Go 的理解里，当我们更新依赖模块到新的 major 大版本时，它认为从技术上说由于不保证向后兼容性它们是不同的模块。所以`v1.x.x`和`v2.x.x`是两个模块，这意味着用户必须手动使用`go get`安装那些已经 import 的模块的新版本，并且给新版本一个**新的指定的 import 引用路径**。

那么这个**新的 import 引用路径**是什么样的呢？由于我们在`go.mod`文件中已经存在了之前我们引用的旧版本依赖模块的 URL 名称，我们需要修改一些东西来区分新旧版本。其实只需要简单的将 major 主版本号以（vX）的形式接到原本 import 引用路径后面，这样用户就能同时使用一个依赖模块的多个版本了。让我们实际操作下：

![新的major主版本](http://wx1.sinaimg.cn/large/9a1da786gy1g2u3whmqa5j20m80dutb2.jpg)

上图可以看到，我们修改了`Add`函数的实现来检查是否传入至少两个参数，并在不符合的条件下返回 error 错误作为第一个返回值，而正常情况下则会返回无错误以及实际的数字之和作为第二个返回值。

现在这个`Add`函数的实现和原本的`v1.x.x`版本仅返回一个数值的实现差别很大，旧代码需要修改。这意味着我们的代码不能向后兼容。所以下一个发布版本理应变更为`v2.0.0`，以保证 Go 能正确的认为这是不同的模块，而不会让过去的代码自动升级到这个版本。

如果你注意到，我们为新的 major 主版本创建了新的 branch 分支**v2**。这会在我们需要继续维护**v1**版本去处理 bug 和优化代码的时候轻松一些。

现在我们要更新`go.mod`文件，在模块申明的部分加入版本号的后缀。（译者：原文为 prefix，我觉得实际应该是想表达 suffix）

![更新到v2分支](http://ws1.sinaimg.cn/large/9a1da786gy1g2u4bew5aqj20m80ecgp0.jpg)

虽然这里 import 引用路径有点让人迷惑，但是 Go 还是能够理解`vX`标记的含义，并正确的解析模块引用。`vX`是固定的，需要精确的对应 SemVer 语义化版本号的 major 主版本，例如**v2**就是对应`v2.x.x`的发布版本号。

![安装v2版本依赖模块](http://ws1.sinaimg.cn/large/9a1da786gy1g2u4gzp0ftj20m80hh0vp.jpg)

在上面的例子中，我们安装了`nummanip`模块的新 major 主版本。由于这是 major 主版本的更新，需要手动的使用`go get`在项目中安装。而新的模块也需要使用新的标记来 import 引用。

需要给我们新版本模块里的包名另起一个别名是比较麻烦的事情。由于我们 import 引用了同一个包的两个不同版本，我们需要对其中一个 alias 起一个别名来解决包名变量重复的冲突。在这里，我们对`v2/calc`包起了`calcNew`的别名，并使用`calcNew.Add`来调用新版函数。
![新的go mod文件](http://ws2.sinaimg.cn/large/9a1da786gy1g2u4on78xij20m807jt9s.jpg)

![加入v2后的模块缓存状况](http://ws3.sinaimg.cn/large/9a1da786gy1g2u4p0wsbmj20m80a3408.jpg)

你可以看到，`go get`命令写入了新版本的模块信息到`go.mod`文件中，并将新版本的模块下载到了模块缓存路径里。

## 编译运行可执行的模块

当我们编写一个可执行的模块时，可以使用`go run <filename>`或者是`go run path/*.go`来运行模块。当编译时，可以使用`go build`命令编译模块，其二进制输出会生成在当前的目录下，或者使用`go install`命令会将模块的二进制输出放到`$GOPATH/bin`目录下。

> 对于非可执行的模块，如我们例子中的`nummanip`模块，不像**Go1.11 之前**的行为，我们无法使用`go install`命令来生成 package archives。这是由于`go install`命令无法从 Git 的历史提交或 Git 的标签信息中预测模块的版本号（SemVer 语义化版本）。同样的 Go Modules 也不能将包存成 binary archives 的形式，像窝在[packages 教程](https://medium.com/rungo/everything-you-need-to-know-about-packages-in-go-b8bac62b74cc)中表述的那样。

## 间接依赖模块（Indirect Dependencies）

上文中我们使用了间接依赖模块这个名称，但并没有解释它。顾名思义，其实间接依赖模块就是在我们的模块中没有直接使用到的模块。直接依赖的模块是我们在代码中声明使用到的模块，而间接依赖模块，则是被直接依赖模块所依赖的模块。

`go.mod`文件会记录下直接和间接依赖模块，并使用`//indirect`来标识间接使用模块，如下图：
![直接和间接依赖模块](http://ws1.sinaimg.cn/large/9a1da786gy1g2u5lsa95tj20m80c9q52.jpg)

在上图中，我们知道`github.com/fatih/color`是一个直接依赖模块，因为我们在代码中 import 引用了它。当我们运行或编译该模块时，Go 会更新`go.mod`文件并且添加`indirect`注释到非直接引用的模块后面。

我希望上面的这些关于 Go Modules 的介绍足够清楚了，但是还是有一个问题：当我们没有在模块引用申明中写出版本后缀（在`go.mod`文件的依赖模块部分）时，Go 会自动使用哪一个版本的模块？答案是最新的`v1.x.x`版本，因为在默认情况下 Go 认为版本后缀是**v1**。

## 最小版本选择（MVS）

说到了现在，我们可以 import 引用同一个依赖模块的不同版本，不过需要他们的 major 大版本号不同。当两个版本仅在 minor 次要版本和 patch 补丁版本号上有不同时我们却没有办法同时使用多个版本（因为在写 import 引用申明时，这些 minor 和 patch 版本号不同的模块并没有区别）。

![依赖复制问题](http://wx1.sinaimg.cn/large/9a1da786gy1g2u5x7vdnwj20dl08xmx9.jpg)

如上图，我们有一个模块依赖了**模块 A**和**模块 B**。这两个模块都同事依赖了同样的模块**模块 1**。但是问题出现了，**模块 A**依赖的是`v1.0.1`版本的**模块 1**，而**模块 B**依赖的是`v1.0.2`版本的**模块 1**。每个模块都定义了**minimal version**最小依赖版本以保证它们自身可以正常工作。所以如果我们使用`v1.0.1`版本的**模块 1**用于最后的编译，那么**模块 B**可能运行会有异常或者直接就无法进行编译。

因此在编译中，我们只能用使用此依赖的一个版本，这是一个**Diamond Dependency Problem 钻石依赖问题**，如下图所示：

![Diamond Dependency Problem钻石依赖问题](http://ws2.sinaimg.cn/large/9a1da786gy1g2u668cp9hj20dl08wglv.jpg)

正如 Go 所推荐的，同一个模块的多个版本，如果使用的是一个主版本号时，它应该是是能够向后兼容的。这样，当我们在使用`v1.0.2`版本用于编译运行时，它会能够包含`v1.0.1`版本的所有能力。Go 将这称为**Minimal Version Selection 最小版本选择**(其实也意味着在所有最小依赖版本号中选择最大的那个)。MVS 的详细解释在[这篇文章](https://research.swtch.com/vgo-mvs)中。

![MVS最小版本选择](http://wx4.sinaimg.cn/large/9a1da786gy1g2u6ko7emrj20dl08w74j.jpg)

所以最后我们应当选择`v1.0.2`版本的**模块 1**。

# 结语

`Go Modules`现在仍然还在 beta 测试阶段，未来可能会有一些新的变动。由于我不能时刻了解这些信息，所以如果有新的变化出现，请随时与我联系。非常感谢。

# 附赠的小 Tips 提示

1. 如果你现在想发布一个模块，但是它的`go.mod`文件还没有记录下模块源码中的依赖模块信息，你可以使用`go build ./...`命令来处理这个问题。其中`./...`的形式会匹配此模块下所有的包并且下载其中还没有下载的依赖模块。这样就可以保证在发布模块之前所有使用到的依赖都被`go.mod`文件所记录下来了。
1. 如果认为`go.mod`文件中记录的一些依赖是当前项目中不再使用的，可以使用`go mod tidy`命令来自动清理这些未使用的依赖模块。
1. 有时在跑一些自动化测试时，有一定几率我们的测试机会遇到网络问题而导致无法下载依赖模块。此时我们需要预先提供依赖。这个被称为**vendoring**，可以尝试使用`go mod vendor`命令去将所有的依赖下载到`vendor文件夹`下（在`go.mod`所在的目录），当使用`go build`命令时，你可以使用`go build -mod vendor`命令强制指定让 Go 使用`vendor`目录下的依赖进行编译，而不是默认的模块缓存路径`$GOPATH/pkg/mod`。
1. `go mod graph`命令会展示模块依赖关系图
1. [GopherCon 2018 中的演讲](https://www.youtube.com/watch?v=F8nrpe0XWRg)可以简明的让你理解**Go Dependency Management with versioning**
1. 官方的[`Go Modules文档链接`](https://github.com/golang/go/wiki/Modules)
