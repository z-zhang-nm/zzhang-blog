---
title: "028 实现strStr"
date: 2020-09-04T13:30:38+08:00
categories:
- Leetcode
- 字符串
tags:
- 双指针
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[题目链接](https://leetcode-cn.com/problems/implement-strstr/)
<!--more-->
## 题目
　　给定一个 haystack 字符串和一个 needle 字符串，在 haystack 字符串中找出 needle 字符串出现的第一个位置 (从0开始)。如果不存在，则返回  -1，当 needle 是空字符串时，返回 0。

　　示例1：
> 输入: haystack = "hello", needle = "ll"  
输出: 2

　　示例2：
> 输入: haystack = "aaaaa", needle = "bba"  
输出: -1

## 题解一
　　遍历haystack字符串，遇到当前字符等于needle第一个字符的时候停下来，遍历needle字符串进行判断。

　　并不需要遍历整个haystack字符串，而是遍历到剩下的长度和needle字符串长度相等的位置即可，这样可以提高运算效率。
```cpp
int strStr(string haystack, string needle) {
    int pos = 0, m = haystack.size(), n = needle.size();
    if(needle.size()==0) return 0;
    // while(pos < m){
    while(pos <= m-n){//注意不要进行不必要的判断
        if(haystack[pos] == needle[0]){
            int i = 0;
            for(; i < n; ++i){
                if(needle[i] != haystack[pos+i]) break;
            }
            if(i == n) return pos;
        }
        pos++;
    }
    return -1;
}
```