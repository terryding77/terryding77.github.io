---
title: 正则匹配一个数字(python实现)
date: 2017-04-15 07:09:02
tags: 
    - python
    - 正则
categories:
    - [算法]
---
## 问题描述
给定一组字符串，判断该字符串是否为一个合法的数字，要求如下
1. 基本整数数字是0-9的组合
1. 整数不可有前导0 (如: 012就不合法)
1. 小数包含(x.y, .y, x.)三种形式，此时x和y符合第1条且可以有前导0
1. 无论整数或小数都可以选择在最前方加入+-之一或者不加，以表达该数字的正负
1. 数字支持"x^y"的形式以表达x的y次方的意义，^不能作为一个数字的开头或结尾，同时x和y均为符合前4条条件的数字
1. 数字支持"xey"的形式以表达x乘以10的y次方的意义，e不能作为一个数字的开头或结尾，同时x符合前4条条件，y符合条件1和4(即：允许前导0的整数)

## 测试样例
* "+1.23" is True
* "-1.23" is True
* "1.23" is True
* ".23" is True
* "1." is True
* "0." is True
* "+123" is True
* "-123" is True
* "123" is True
* 
* "1.23e+123" is True
* "1.23e-123" is True
* "1.23e123" is True
* "1.23e0123" is True
* 
* "1.23^+123" is True
* "1.23^-123" is True
* "1.23^123" is True
* 
* "1.23^+1.23" is True
* "1.23^-1.23" is True
* "1.23^1.23" is True
* "1.23^.23" is True
* "1.^1." is True
* "1.^0." is True
* 
* "" is False
* "a." is False
* "." is False
* 
* "-1.2.3" is False
* "-1.-2" is False
* "0123" is False
* 
* "1.23e1.2" is False
* "1.23e" is False
* "1.23e1e2" is False
* "1.23e1^2" is False
* 
* "1.23^1.2.3" is False
* "1.23^" is False
* "1.23^0123" is False
* "1.23^1^2" is False
* "1.23^1e2" is False

## 思路
最开始的思路是先确定数字中是否包含e或者^符号，如果有，用其将数字切开，分别对前后进行判断，后来整理清楚要求后，发现可以用正则来进行匹配，正则的整体方案也基本等价于一开始的思路
1. 对于小数使用\d*\.\d+ 来匹配x.y .y的形式， \d+\. 来匹配x.的形式
1. 对于整数使用[1-9]\d*来匹配无前导0的形式，\d+ 来匹配有前导0的形式
1. 对以上的几种形式再与- + e ^ 等符号进行按要求的连接即可形成完整的正则

## 代码如下：
```python
import re


def numberCheck(numberStr):
    numberRegex = re.compile("[-+]?("
                                    "(\d*\.\d+)|"   # match x.y .y format
                                    "(\d+\.)|"  # match x. format
                                    "([1-9]\d*)"  # match Integer format(without lead zero) 
                                    ")"  # a simple number (both Integer and Double)
                             "("
                                 "(e[+-]?\d+)"   # if "e" in number, we need a Integer(can lead with zero) below 
                             "|"
                                 "(\^[+-]?((\d*\.\d+)|(\d+\.)|([1-9]\d*)))"  # if "^" in number, we need a simple number below
                             ")?"
                             )
    return numberRegex.fullmatch(numberStr) is not None


def testNumberCheck():
    assert numberCheck("+1.23") is True
    assert numberCheck("-1.23") is True
    assert numberCheck("1.23") is True
    assert numberCheck(".23") is True
    assert numberCheck("1.") is True
    assert numberCheck("0.") is True

    assert numberCheck("+123") is True
    assert numberCheck("-123") is True
    assert numberCheck("123") is True

    assert numberCheck("1.23e+123") is True
    assert numberCheck("1.23e-123") is True
    assert numberCheck("1.23e123") is True
    assert numberCheck("1.23e0123") is True

    assert numberCheck("1.23^+123") is True
    assert numberCheck("1.23^-123") is True
    assert numberCheck("1.23^123") is True

    assert numberCheck("1.23^+1.23") is True
    assert numberCheck("1.23^-1.23") is True
    assert numberCheck("1.23^1.23") is True
    assert numberCheck("1.23^.23") is True
    assert numberCheck("1.^1.") is True
    assert numberCheck("1.^0.") is True

    assert numberCheck("") is False
    assert numberCheck("a.") is False
    assert numberCheck(".") is False

    assert numberCheck("-1.2.3") is False
    assert numberCheck("-1.-2") is False
    assert numberCheck("0123") is False

    assert numberCheck("1.23e1.2") is False
    assert numberCheck("1.23e") is False
    assert numberCheck("1.23e1e2") is False
    assert numberCheck("1.23e1^2") is False

    assert numberCheck("1.23^1.2.3") is False
    assert numberCheck("1.23^") is False
    assert numberCheck("1.23^0123") is False
    assert numberCheck("1.23^1^2") is False
    assert numberCheck("1.23^1e2") is False


if __name__ == '__main__':
    testNumberCheck()
```
