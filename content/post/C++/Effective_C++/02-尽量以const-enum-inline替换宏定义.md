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
# 1. 对于单纯常量，最好以const对象或enum替换#define

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

## 替换#define时两种需要注意的情况

### 1. 定义常量指针
常量定义式通常放在头文件中以便被不同的源码引入，因此有必要将指针（不只是指针所指的对象）声明为常量，比如声明一个常量字符串时必须写两次`const`：
```cpp
const char* const AuthorNmae = "Scott Meyers";
```
往往使用`string`比`char *`更好：
```cpp
const std::string AuthorName("Scott Meyers");
```

### 2. class专属常量
为了将常量的作用域限制于`class`内，必须让其成为类的成员，而为了确保此常量至多有一个实体，需要将其声明为`static`的：
```cpp
class A{
private:
  static const int len = 5; //声明，in-class初值设定
  int nums[len]; //可以使用
};
```
注意`len`仅仅是声明而不是定义，通常`C++`要求对所使用的任何东西提供一个定义式，但当`class`专属常量是`static`且为整数类型(int, char, bool)时，可以不提供定义式，只要不取它们的地址，否则需要提供如下定义式：
```cpp
const int A::len; // 声明时已有初值，定义时可以不设初值
```

> 注意#define并不重视作用域，一旦宏被定义，在其后的编译过程中都有效，除非在某处被#undef，即其不提供封装性，而class专属常量可以被封装

除非`class`在编译期间需要一个`class`常量值，任何时候都应将初值放在定义式，但若编译器不允许任何`in-class`初值设定，可以用`the enum hack`补偿做法，因为一个属于枚举类型的数值可以当`int`使用：
```cpp
class A{
private:
  enum {len = 5};
  int nums[len];
};
```
## #define, const or enum ?
1. 取一个enum的地址是不合法的，取#define的地址通常也不合法，但是取一个const的地址是合法的；若不希望别人通过指针或引用指向你的整数常量，请使用enum
2. 编译器不会为整数型const对象设定另外的存储空间，除非有指针或引用指向它，导致额外的内存分配，而enum不会导致非必要的内存分配

# 2. 对于形似函数的宏，最好以inline函数替换#define
宏定义函数可能会带来很多问题：

例：

```cpp
// 无论何时写出这种宏，必须为宏中所有实参加上小括号
#define CALL_WITH_MAX(a,b) f((a) > (b) ? (a) : (b))
```

即使为所有实参都加了小括号，还是可能会出现未预料的问题：
```cpp
int a = 5, b = 0;
CALL_WITH_MAX(++a, b); // a被累加两次
CALL_WITH_MAX(++a, b+10); // a被累加一次
```

用`template inline`函数替代：
```cpp
template<typename T>
inline void callWithMax(const T& a, const T& b) {
  f(a > b ? a : b);
}
```
