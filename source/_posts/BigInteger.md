---
title: 大数快速幂(c++实现)
date: 2017-04-09 20:43:09
tags: [cpp, 大数运算, 快速幂]
categories: [cpp, 大数运算, 快速幂]
---
## 问题描述
给定两个int范围的整数m和n(m<10^9, n<10^5)，求出m的n次方的值，并使用string类型返回该数字。
## 思路
由m和n的范围可以看出，m的n次方可能是个很大的数字:m可以取到约10的9次方，所以m的n次方最大可以约10的9*n次方，使用10进制表示可以是1后面跟上9*n个0，如果方法不合适，可能根本无法计算，对此，我们需要使用**快速幂**的思想来帮助简化n次方运算, 同时对超越int大小范围的乘法运算，使用vector容器来保持数字的值，由于int范围略大于10^9, 我们在vector中每个元素存储10^4大小的数字，这样保证在乘法运算时也不至于超过int大小。
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
