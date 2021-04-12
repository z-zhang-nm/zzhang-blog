---
title: "Const类成员函数"
date: 2021-04-12T16:30:02+08:00
categories:
- C++
- 常见问题
tags:
- const类成员函数
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　只有被声明为const的成员函数才能被const类对象调用
<!--more-->
# 声明const成员函数
```cpp
class A {
  public:
    void func() const;
};
```

在类外定义函数时也需要加上const关键字：
```cpp
void A::func() const {

}
```

> const成员函数不允许修改类的数据成员

> const成员函数可以被具有相同参数列表的非const成员函数重载，这种情况下类对象的常量性决定调用哪个函数
```cpp
class A{
  public:
    void func() const;
    void func();
};
```
