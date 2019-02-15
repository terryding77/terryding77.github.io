---
title: 大数快速幂(c++实现)
date: 2017-04-09 20:43:09
tags:
  - cpp
  - 大数运算
  - 快速幂
categories:
  - [算法]
---

## 问题描述

给定两个 int 范围的整数 m 和 n(m<10^9, n<10^5)，求出 m 的 n 次方的值，并使用 string 类型返回该数字。

## 思路

由 m 和 n 的范围可以看出，m 的 n 次方可能是个很大的数字:m 可以取到约 10 的 9 次方，所以 m 的 n 次方最大可以约 10 的 9*n 次方，使用 10 进制表示可以是 1 后面跟上 9*n 个 0，如果方法不合适，可能根本无法计算，对此，我们需要使用**快速幂**的思想来帮助简化 n 次方运算, 同时对超越 int 大小范围的乘法运算，使用 vector 容器来保持数字的值，由于 int 范围略大于 10^9, 我们在 vector 中每个元素存储 10^4 大小的数字，这样保证在乘法运算时也不至于超过 int 大小。

## 代码如下：

```cpp
#include <bits/stdc++.h>
using namespace std;

class BigInteger {
    vector<unsigned int> numberArray;
    bool isNegative;
    static const unsigned int MOD = 10000;
public:
    BigInteger(int n) {
        isNegative = n < 0;
        unsigned int un = abs(n);
        numberArray.clear();
        if(un == 0) {
            numberArray.push_back(0);
        } else {
            while(un) {
                numberArray.push_back(un % MOD);
                un /= MOD;
            }
        }
    }

    BigInteger(const BigInteger & original) {
        numberArray.reserve(original.numberArray.size());
        copy(original.numberArray.begin(), original.numberArray.end(), back_inserter(numberArray));
        isNegative = original.isNegative;
    }

    string toString() {
        string ret = isNegative ? "-" : "";
        for(auto it = numberArray.crbegin(); it != numberArray.crend(); it ++) {
            ret += to_string(*it);
        }
        return ret;
    }

    BigInteger pow(int n) {
        BigInteger ret(1), mul(*this);
        while(n) {
            if(n & 1) {
                ret *= mul;
            }
            n >>= 1;
            mul *= mul;
        }
        return ret;
    }

    void format() {
        unsigned int more = 0;
        for(int i = 0; i < numberArray.size(); i ++) {
            unsigned int tmp = numberArray[i] + more;
            more = tmp / MOD;
            numberArray[i] = tmp % MOD;
        }
        while(more) {
            numberArray.push_back(more % MOD);
            more /= MOD;
        }
        while(numberArray.size() > 1 && numberArray[numberArray.size() - 1] == 0) {
            numberArray.pop_back();
        }
    }

    BigInteger& operator *=(const BigInteger& mul) {
        return *this = (*this) * mul;
    }

    BigInteger operator *(const BigInteger& b) {
        BigInteger ret(0);
        ret.numberArray.resize(numberArray.size() + b.numberArray.size(), 0);
        for(int i = 0; i < numberArray.size(); i ++) {
            for(int j = 0; j < b.numberArray.size(); j ++) {
                ret.numberArray[i + j] += numberArray[i] * b.numberArray[j];
            }
        }
        ret.format();
        ret.isNegative = isNegative ^ b.isNegative;
        return ret;
    }
};

int main() {
    int m, n;
    while(cin>>m>>n) {
        if(n == 0 && m == 0) break;
        BigInteger bigM(m);
        BigInteger result = bigM.pow(n);
        cout<< result.toString()<<endl;
    }
    return 0;
}
```
