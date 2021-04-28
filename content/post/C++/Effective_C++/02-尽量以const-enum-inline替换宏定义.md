---
title: "02 尽量以const Enum Inline替换宏定义"
date: 2021-04-27T22:02:55+08:00
categories:
- C++
- Effective_C++
tags:
- C++
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

Prefer consts, enum, inlines to #define

<!--more-->

> 宏定义在预处理阶段就会被替换，可能并未进入**记号表**中，当运用此宏定义的地方在编译阶段出错时，可能会带来困惑。

例：

```cpp
#define ASPECT_RATIO 1.653
```

若`ASPECT_RATIO`被定义在一个非你写的头文件内，你肯定对`1.653`毫无概念，追踪它会浪费大量时间，解决办法是**以一个常量替换上述宏定义**：

```cpp
const double SapectRatio = 1.653;
```

使用常量可能比使用宏定义产生较小量的目标码，因为预处理器会“盲目地”对宏进行替换导致目标码出现多份`1.653`，若改用常量不会出现这种情况。

# 两种需要注意的情况

## 1. 定义常量指针

