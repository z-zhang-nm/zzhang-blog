---
title: "Override和final关键字"
date: 2020-07-29T15:18:03+08:00
categories:
- C++
tags:
- C++基础
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[参考链接](https://www.kancloud.cn/wangshubo1989/new-characteristics/99708)
<!--more-->
# Override和final关键字

## 1 概述
　　C++11之前没有**继承控制关键字**，C++11添加了两个继承控制关键字：`override`和`final`。`override`关键字确保在派生类中声明的重载函数跟基类的虚函数有相同的签名(函数名和参数列表一起构成了函数签名)；`final`关键字阻止类的进一步派生和虚函数的进一步重载。

## 2 虚函数重载
　　重载虚函数的两个常见错误为：**无意中重载**和**签名不匹配**。

### 2.1 无意中重载
　　有时候可能只是声明了一个与基类的某个虚成员函数具有相同名字和签名的成员函数而导致无意中重载了这个虚函数，而这个bug通常很难被发现。

```cpp
class A {
 public:
  virtual void fun();
};

class B : A {};
class C {};
class D : A, C {
 public:
  void fun();
};
```

　　上面的程序中，不能确定成员函数`D::fun()`是否故意重载了`A::fun()`，它们的函数名字和参数列表都一样，可能是个偶然发生的重载。

### 2.2 签名不匹配
　　签名不匹配会导致创建一个新的虚函数而不是重载基类的虚函数。
```cpp
class A{
public:
    virtual void fun(int);
};

class B:A{
public:
    virtual void fun(double);
};
```

　　上面的程序在类B中本来是要重载基类A中的虚函数`fun()`的，而由于B类中`fun()`与基类`fun()`签名不同，结果创建了一个新的虚函数而非对基类函数的重载。

```cpp
B *p = new B;
p->fun(1); //A::fun()
p->fun(1.0); //B::fun()
```

## 3 问题解决
　　C++11中`override`关键字明确表示一个函数是对基类中一个虚函数的重载，且它会检查基类虚函数和派生类中重载函数的签名不匹配问题，如果签名不匹配，编译器会发出错误信息。

```cpp
class A{
public:
    virtual void fun(int);
};

class B:A{
public:
    virtual void fun(double) override; //编译错误
};
```
## 4 final关键字
　　关键字`final`有两个用途：阻止从类继承和阻止一个虚函数重载。

### 4.1 阻止从类继承
　　无子类类型：

```cpp
class A {
/*..*/
}final;

class B:public A{}; //编译错误
```
### 4.2 阻止一个虚函数重载

```cpp
class A{
public:
  virtual void func() const;
};
class  B: A
{
public:
  void func() const override final; //OK
};
class C: B
{
public:
 void func() const; //error, B::func is final
};
```

　　无论`C::func()`是否声明为override，编译器都会报错，一旦一个虚函数被声明为final，派生类不能再重载它。
