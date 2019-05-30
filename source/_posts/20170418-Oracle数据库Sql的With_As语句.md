---
title: Oracle数据库Sql的With As语句
tags:
  - Oracle
  - sql
  - docker
categories:
  - [数据库]
abbrlink: 53462dca
date: 2017-04-18 02:23:56
---

# 问题描述

今天碰到一道 sql 的题目，问题简化下来就是一张存有 id 和订单号的表格 orders，筛选出拥有最多订单的所有 id。

# 样例

| id  | orderNumber |
| :-- | :---------- |
| 1   | 0001        |
| 1   | 0003        |
| 2   | 0006        |
| 3   | 0008        |
| 3   | 0010        |

这张表经过查询语句应当返回：

| id  |
| :-- |
| 1   |
| 3   |

原因是 id 为 1 和 3 的用户都拥有 2 条订单，同时 2 条订单是最多的单个用户所拥有的订单数量。

# 解决方法

对于这题主要的就是要能获得一张 id 对应 id 拥有订单总数的表格，然后再对这张表格做处理。

这样的思路在 mysql 下我的写法是这样的

```sql
select t1.id
from (select id, count(orderNumber) as counts
        from orders group by id) as t1,
     (select count(orderNumber) as max_counts
        from orders group by id
        order by count(orderNumber) desc
        limit 1) as t2
where t1.counts = t2.max_counts;
```

![mysql-screenshot](http://wx4.sinaimg.cn/large/9a1da786gy1g06xhybd5lj20wf0qdmzn.jpg)

其中 t1 表完成 id 对应拥有订单总数的表格，t2 是 t1 中最大的订单数量，但写法上可以发现 t1 和 t2 的构造有很大一部分是冗余的，但我一时也无法找到合适的写法去除这个冗余。

在查找解决方法的时候我尝试着对应我在 python 中使用的 with as 写法来搜索，发现 sql 中也有这种写法，可是在 mysql 中尝试不得成功。看大家说 Oracle 可以，我就想着在 Oracle 中试试。

# Oracle 数据库安装

简单的搜索了 Oracle 数据的的安装教程，感觉好像很麻烦，而我又是只想简单使用，想着应该可以用 docker 来安装。

![docker-search-oracal](http://wx3.sinaimg.cn/large/9a1da786gy1g06xhyfo0rj211x0i30xi.jpg)

看到了排名第一的 Oracle 镜像，转战 github 查看下[源码仓库](https://github.com/wnameless/docker-oracle-xe-11g)，其中包含了 dockerfile 和使用指南等，对我来说，如何运行 docker 镜像以及登录 Oracle 命令行是我想知道的，稍微阅读下使用指南，知道了镜像对应的端口以及 Oracle 数据库的默认用户名密码，开始运行镜像并登录：

![docker-oracle-11g-usage](http://ws1.sinaimg.cn/large/9a1da786gy1g06xhyl2f4j20r00s8dke.jpg)

# Oracle 数据库 with as 写法

with as 的写法大致为`with 别名 as (表的定义)`这样的形式，其中表的定义可以使用 select 语句或者其他能产生表的方法。
对于上述题目，我使用 with as 的写法如下：

```sql
with t1 as (select id, count(orderNumber) as counts from orders group by id),
     t2 as (select max(counts) as max_counts from t1)
select t1.id
    from t1, t2
    where t1.counts = t2.max_counts;
```

![oracle-screenshot](http://ws4.sinaimg.cn/large/9a1da786gy1g06xhy7ewxj20rs0n7jt6.jpg)

with as 的写法可以并列多条，后面的可以使用前面已经定义好的表，如 t2 的定义就使用了 t1 表。

有了这样的语法，在书写一些重复运算比较多的 sql 时就可以将其使用 with as 优先定义，就有点像使用函数的感觉。这在提高效率的同时，可读性也提高不少。

# ps: 测试数据导入

```sql
# mysql database test env settings
# choose database first by "use your-test-database-name;"
create table orders(id int, orderNumber VARCHAR(10));
insert into orders values (1, "0001"), (1, "0003"), (2, "0006"), (3, "0001"), (3, "0010");
select * from orders;


# Oracle database test env settings
create table orders(id int, orderNumber VARCHAR(10));
insert all
    into orders values (1, '0001')
    into orders values (1, '0003')
    into orders values (2, '0006')
    into orders values (3, '0001')
    into orders values (3, '0010')
select 1 from dual;
select * from orders;

# normal env settings;
create table orders(id int, orderNumber VARCHAR(10));
insert into orders values (1, '0001');
insert into orders values (1, '0003');
insert into orders values (2, '0006');
insert into orders values (3, '0001');
insert into orders values (3, '0010');
select * from orders;
```
