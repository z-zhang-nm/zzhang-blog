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
## 引言
　　C语言类型转换：
> `(T) expression`

　　C++类型转换：
> `static_cast<T>(expression)`  
`dynamic_cast<T>(expression)`  
`reinterpret_cast<T>(expression)`  
`const_cast<T>(expression)`

　　C语言类型转换为强制性的，即可以在任意类型之间转换，且不易debug。
---
## **static_cast**
　　`static_cast`与C语言中强制类型转换功能基本一样。
> `static_cast<type_id> ( expression )`

　　该运算符把`expression`转换为`type_id`类型，但**没有运行时检查来保证转换的安全性**，主要有如下几种用法：
1. 用于类层次结构中基类和派生类之间的指针转换，要注意的是进行上行转换（把派生类指针或引用转换为基类表示）时是安全的，进行下行转换时，由于没有动态类型检查，因此是不安全的
2. 用于基本数据类型之间的转换，这种转换的安全性也需要人为保证
3. 把空指针转换为目标类型的空指针
4. 把任何类型的表达式转换为void类型

```cpp
class Base{
    //...
};
class Derived : public Base{
    //...
};
void main(){
    //基本类型转换
    int i;
    float f = 1.1;
    i = static_cast<int>(f);
    //上行转换
    Derived d;
    Base b = static_cast<Base>(d);
    //下行转换
    Base bb;
    // Derived dd = static_cast<Derived>(bb);//编译错误
    Base *pB = new Base;
    Derived *pD = static_cast<Derived*>(pB);//编译通过但不安全（例如访问子类成员）
}
```

　　`static_cast`本质上是传统c语言强制转换的替代品，要注意的是`static_cast`不能转换掉`expression`的`const`、`volitale`、或者`__unaligned`属性。
---
## **const_cast**
　　顾名思义，`const_cast`修改表达式的`const`属性，C++中只有这一运算符可以移除`const`属性。
> `const_cast<type_id> (expression)`

　　该运算符用来修改类型的`const`或`volatile`，除了`const`或`volatile`修饰外，`type_id`和`expression`类型是一样的，有如下几种用法：
1. 常量指针转换为非常量指针，且仍指向原来的对象
2. 常量引用转换为非常量引用

```cpp
const int a = 1;
// int *p = &a;//编译错误
int *pa = const_cast<int *>(&a);
*pa = 110;
printf("%d\n", a);//1
printf("%d\n", *pa);//110
printf("0x%08x\n", &a);//0x88b8b5cc
printf("0x%08x\n", pa);//0x88b8b5cc
```
---
## **dynamic_cast**
　　`dynamic_cast`支持运行时识别指针或引用所指向的对象。
> `dynamic_cast<type_id> (expression)`

　　该运算符把`expression`转换为`type_id`类型，且`type_id`必须是类的指针、类的引用或`void*`。

　　如果`type_id`是类指针类型，那么`expression`也必须是一个指针，如果`type_id`是一个引用，那么`expression`也必须是一个引用。

　　该运算符可以在程序执行过程中决定真正的类型，执行转换时首先检查能否成功转换，若可以则转换之，否则转换失败，若是指针则返回空指针，若是引用则抛出bad_cast异常。

　　**dynamic_cast转换符只能用于含有虚函数的类**(具有多态特性)。
```cpp

```