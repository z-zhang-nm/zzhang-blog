---
title: "Ecplicit关键字"
date: 2020-08-20T17:42:19+08:00
categories:
- C++
- StackOverflow
tags:
- C++基础
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[链接](https://stackoverflow.com/questions/121162/what-does-the-explicit-keyword-mean)
<!--more-->
　　C++编译器允许对传入函数的参数做一次隐式转换，这意味着编译器可以通过单参数构造函数将某一类型转换为正确的类型以正确调用构造函数，下面是一个例子：
```cpp
class Foo{
public:
    //单参数构造函数，可以进行参数隐式转换
    Foo(int foo) : m_foo(foo) {}
    int GetFoo() {return m_foo;}
private:
    int m_foo;
};
void Bar(Foo foo){
    int i = foo.GetFoo();
}
int main() {
    Bar(10);
}
```

　　传入Bar函数的实参不是Foo类型的对象，而是int，但是Foo类有使用int做参数的单参数构造函数，因此这一构造函数可以被用来构造Foo对象。

　　在构造函数前加上explicit关键字可以防止编译器使用隐式转换，这样在调用Bar函数时编译器会报错。