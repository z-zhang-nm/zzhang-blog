---
title: "Define与const"
date: 2021-04-12T16:19:59+08:00
categories:
- C++
- 常见问题
tags:
- define与const
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
1. 类型安全检查：const有数据类型，编译器会对其进行安全检查；define只是进行字符替换
2. 编译器处理方式不同：const在编译运行时使用；define在预处理阶段展开，不能对宏定义进行调试
3. 存储方式不同：const需要分配内存，存储于数据段；define是直接替换，不分配内存，存储于代码段
4. 效率：const常量保存在符号表中，程序运行时只有一份拷贝；define在内存中有若干份拷贝