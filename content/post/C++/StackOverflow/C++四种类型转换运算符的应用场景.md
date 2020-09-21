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
　　`static_cast`与C语言中强制类型转换功能基本一样，不提供运行时的检查，所以叫static_cast，需要在编写程序时确认转换的安全性。
> `static_cast<type_id> ( expression )`

　　该运算符把`expression`转换为`type_id`类型，但**转换的时候不会检查类型来保证转换的安全性**，主要有如下几种用法：
1. 用于类层次结构中基类和派生类之间的指针或引用转换，要注意的是进行上行转换（把派生类指针或引用转换为基类表示）时是安全的，进行下行转换时是不安全的
2. 用于基本数据类型之间的转换，这种转换的安全性也需要人为保证
3. 把空指针转换为目标类型的指针（极其不安全）

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
    Derived *pd = new Derived;
    Base *pb = static_cast<Base*>(pd);
    //下行转换
    Base *pB = new Base;
    Derived *pD = static_cast<Derived*>(pB);//编译通过但不安全（例如访问子类成员）
}
```

　　`static_cast`本质上是传统c语言强制转换的替代品，要注意的是`static_cast`不能转换掉`expression`的`const`、`volitale`、或者`__unaligned`属性。

> static_cast can also cast through inheritance hierarchies. It is unnecessary when casting upwards (towards a base class), but when casting downwards it can be used as long as it doesn't cast through virtual inheritance. It does not do checking, however, and it is undefined behavior to static_cast down a hierarchy to a type that isn't actually the type of the object.
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
　　a的地址与pa的值一样，但是为什么a的值与`*pa`不一样呢，这是因为a为常亮，存储在符号表中，一般情况下其不存在地址，只有取其地址的时候会另外开辟内存，且在预编译阶段，常量会被真实数值替换，就像define定义的宏一样，于是，`printf("%d,\n",a)`也就相当于编译成`printf("%d,\n",100)`。

---
## **dynamic_cast**
　　`dynamic_cast`支持运行时识别指针或引用所指向的对象，主要用于执行`安全的向下转型（safe down casting）`，也就是说，要确定一个对象是否是一个继承体系中的一个特定类型。
> `dynamic_cast<type_id> (expression)`

　　该运算符把`expression`转换为`type_id`类型，且`type_id`必须是类的指针、类的引用或`void*`。如果`type_id`是类指针类型，那么`expression`也必须是一个指针，如果`type_id`是一个引用，那么`expression`也必须是一个引用。

　　该运算符可以在程序执行过程中决定真正的类型，执行转换时首先检查能否成功转换，若可以则转换之，否则转换失败，若是指针则返回空指针，若是引用则抛出bad_cast异常。

　　**dynamic_cast转换符只能用于含有虚函数的类(具有多态特性)**，因为类中存在虚函数，就说明它有想要让基类指针或引用指向派生类对象的情况，此时转换才有意义。

　　dynamic_cast支持交叉转换，假设基类A有两个直接派生类B、C，那么，将`B* pB`转换为`C* pC`，这种由派生类B转换到派生类C的转换称之为交叉转换，这种情况下只能使用`dynamic_cast`。

　　dynamic_cast支持多继承，假设有两个基类A1、A2，派生类B从A1、A2中派生，那么，将pB转换为pA1或是pA2，此时只能使用`dynamic_cast`。
```cpp
class Base
{
public:
	virtual void foo(){};
};
class Derived : public Base
{
};

void main()
{
	//基类 -> 子类（错误下行）
	Base *pb1 = new Base;
	Derived *pd1 = dynamic_cast<Derived *>(pb1); //失败，pd1 = NULL
	//子类 -> 子类（正确下行）
	Base *pb2 = new Derived;
	Derived *pd2 = dynamic_cast<Derived *>(pb2); //成功
	//子类 -> 基类
	Base *pb3 = new Derived;
	Base *pd3 = dynamic_cast<Base *>(pb3);		 //成功
	//子类 -> 基类
	Derived *pb4 = new Derived;
	Base *pd4 = dynamic_cast<Base *>(pb4);		 //成功
}；
```
　　下面看一个菱形继承的例子。
```cpp
class A { virtual void f() {}; };
class B :public A { void f() {}; };
class C :public A { void f() {}; };
class D :public B, public C { virtual void f() {}; };

void main()
{
    D *pD = new D;
    //B和C都继承了A，并且都实现了虚函数f()，导致在进行转换时，无法选择一条转换路径
    A *pA = dynamic_cast<A *>(pD); // compile error
    //自行指定一条转换路径
    D *pD = new D;
    B *pB = dynamic_cast<B *>(pD);
    A *pA = dynamic_cast<A *>(pB);
}
```
---
## reinterpret_cast
> `reinterpret_cast<type>(expression)`

　　非常激进的指针类型转换，在编译期完成，可以转换任何类型的指针，所以极不安全。非极端情况不要使用。
```cpp
int *pi;
char *pc = reinterpret_cast<char*>(pi);
```
