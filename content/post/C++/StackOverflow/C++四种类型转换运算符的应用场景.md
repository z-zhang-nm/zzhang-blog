---
title: "C++四种类型转换运算符的应用场景"
date: 2020-08-26T16:08:32+08:00
categories:
- C++
- StackOverflow
tags:
- 类型转换运算符
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[链接](https://stackoverflow.com/questions/332030/when-should-static-cast-dynamic-cast-const-cast-and-reinterpret-cast-be-used)
<!--more-->
---
- **static_cast**是应该第一个尝试使用的cast，它进行的是类型之间的隐式转换（比如int转float，指针转void*等），它也可以调用显式转换函数（或隐式转换函数）。许多情况下，无需明确声明`static_cast`，但是需要注意的是，`T(something)`与`(T)something`是等效的，应该避免使用。`T(something, something_else)`是安全的且一定可以调用构造函数。`static_cast`也可以在继承结构中进行转换，进行向上转换（向基类）时没有必要使用，但是进行向下转换可以使用，除了虚继承的情况。
---
- **const_cast**
---