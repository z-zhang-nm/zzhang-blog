---
title: "Z字形变换"
date: 2020-06-17T17:57:07+08:00
categories:
- Leetcode
tags:
- 字符串
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
## 题目
　　将一个给定字符串根据给定的行数，以从上往下、从左到右进行 Z 字形排列。

　　比如输入字符串为 "LEETCODEISHIRING" 行数为 3 时，排列如下：
```
L   C   I   R
E T O E S I I G
E   D   H   N
```

　　之后，你的输出需要从左往右逐行读取，产生出一个新的字符串，比如："LCIRETOESIIGEDHN"。

　　请你实现这个将字符串进行指定行数变换的函数：
```cpp
string convert(string s, int numRows);
```

## 题解
　　从题目给出的例子可以看出字符串由numRows个子字符串按顺序拼接起来组成，若行数为4：
```
L     D     R
E   O E   I I
E C   I H   N
T     S     G
```
　　先看第一行，L和D之间的字符串索引位置相差6，D和R之间也是相差6，这个6是怎么来的呢？
```
L     D
E   O
E C
T
```
　　可以把上面的字符排列拆分为几个形式一样的排列，易发现L到D之间有一行E和O两个字符，一行E和C两个字符，还有一个T与D组成两个字符，相当于三行两个字符对，因此`pos(D) = pos(L) + 2 * (numRows - 1)`，第二行E和E之间也符合这个规律，但是E和E之间有一个O，这个O与E之间有什么关系呢？
```
E   O
E C
T
```
　　可以看出相当于把numRows减小1行，那么下一行的E和C之间相当于再减去一行，易总结出E和O之间的关系为pos(O) = pos(E) + 2 * (numRows - i - i)，其中i代表目前是第几行（索引从0开始）。

```cpp
string convert(string s, int numRows) {
    if (numRows <= 1) {
        return s;
    }
    int len = s.size();
    int step = 2 * (numRows - 1);
    string ret;
    for (int i = 0; i < numRows; ++i) {
        int pos_upright = i;
        while(pos_upright < len) {
            ret += s[pos_upright];
            int pos_slope = pos_upright + 2 * (numRows - i - 1);
            if ( i > 0 && i < numRows - 1 && pos_slope < len) {
                ret += s[pos_slope];
            }
            pos_upright += step;
        }
    }
    return ret;
}
```