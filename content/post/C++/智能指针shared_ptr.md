---
title: "智能指针shared_ptr"
date: 2020-07-28T14:49:40+08:00
categories:
- C++
tags:
- C++基础
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
# 智能指针

## 1 问题抛出

　　C++程序中new出来的指针需要delete掉，在一些小型项目中程序员一般不会忘记手动delete，但是随着程序规模扩大，很有可能会忘记delete。随着指针的赋值，会将同一对象的引用散播到程序的不同地方，但是对象只需要释放一次，若在程序某一处delete了这个对象，其它指向这个对象的指针就变成了“野指针”，但是若都不delete，就会引起内存泄漏。

## 2 C++11智能指针

　　自C++11起，C++标准提供两类智能指针：
1. `shared_ptr`：实现共享拥有，多个智能指针可以指向相同对象，该对象和相关资源会在**最后一个引用被销毁**时释放
2. `unique_ptr`：实现独占式拥有，保证同一时间只能有一个智能指针可以指向该对象，它对于**new创建对象后因发生异常而忘记调用delete**很有用

## 3 shared_ptr

　　智能指针是模板类，在创建share_ptr时需要指定其指向的类型，shared_ptr负责在不使用实例时释放有它管理的对象，同时它可以自由地共享它指向的对象。

　　shared_ptr使用“引用计数”的方法管理对象，即每个shared_ptr都有一个关联的计数值，无论何时拷贝一个shared_ptr，计数器都会递增（例如用一个shared_ptr初始化另一个shared_ptr，或将它作为参数传递给一个函数以及作为函数的返回值时）；当给shared_ptr赋一个新值或shared_ptr被销毁时，计数器就会递减；一旦引用计数器为0时，就会自动释放指针指向的资源。

```cpp
#include <iostream>
#include <string>
#include <tr1/memory>

using namespace std;

class Test
{
public:
    Test(string name)
    {
        name_ = name;
    }
    ~Test() {}

    // private:
    string name_;
};

int main()
{
    /* 类对象 原生指针构造 */
    tr1::shared_ptr<Test> pStr1(new Test("object"));
    cout << pStr1->name_ << endl;
    /* use_count()检查引用计数 */
    cout << "pStr1 引用计数：" << pStr1.use_count() << endl; //1
    /* unique()来检查某个shared_ptr是否是原始指针唯一拥有者 */
    cout << pStr1.unique() << endl; //1

    tr1::shared_ptr<Test> pStr2 = pStr1;
    cout << "pStr1 引用计数：" << pStr1.use_count() << endl; //2
    cout << "pStr2 引用计数：" << pStr2.use_count() << endl; //2
    cout << pStr1.unique() << endl; //0

    return 0;
}
```

## 4 错误用法：循环引用

　　循环引用可以说是引用计数最大的缺点，循环引用即两个对象互相使用一个shared_ptr成员变量指向对方（你中有我，我中有你）。

```cpp
#include <iostream>
#include <string>
#include <tr1/memory>

using namespace std;

class Children;
class Parent
{
public:
    ~Parent() { cout << "Parent destructor" << endl; }

    void PrintUseCount()
    {
        cout << "pChildren use_count: " << children_.use_count() << endl;
    }

    tr1::shared_ptr<Children> children_;
};

class Children
{
public:
    ~Children() { cout << "Children destructor" << endl; }

    void PrintUseCount()
    {
        cout << "pParent use_count: " << parent_.use_count() << endl;
    }

    tr1::shared_ptr<Parent> parent_;
};

void Test()
{
    tr1::shared_ptr<Parent> pParent(new Parent());
    tr1::shared_ptr<Children> pChildren(new Children());

    cout << "pParent use_count: " << pParent.use_count() << endl; //1，pParent与new的对象绑定
    cout << "pChildren use_count: " << pChildren.use_count() << endl; //1

    pParent->PrintUseCount(); //0，因为pParent中的children_还没有绑定对象
    pChildren->PrintUseCount(); //0

    if (pParent && pChildren)
    {
        pParent->children_ = pChildren;
        pChildren->parent_ = pParent;
    }

    cout << "pParent use_count: " << pParent.use_count() << endl; //2
    cout << "pChildren use_count: " << pChildren.use_count() << endl; //2

    pParent->PrintUseCount(); //2
    pChildren->PrintUseCount(); //2
}

int main()
{
    Test();
    return 0;
}
```

　　上面程序`Test()`函数退出后并不会调用pParent和pChildren的析构函数，因为pParent和pChildren对象互相引用，它们的引用计数都是1，不能自动释放。这两个对象再也无法访问到了，因此引起了“内存泄漏”。
　　
## 5 weak_ptr打破循环引用

　　weak_ptr与一个shared_ptr绑定，但是不参与引用计数的计算，无论是否有weak_ptr指向，最后一个指向对象的shared_ptr被销毁时，对象就会被释放。

　　在需要时，weak_ptr可以生成一个与它绑定的shared_ptr共享引用计数的新的shared_ptr。

　　weak_ptr没有重载*和->运算符，因此不可以直接通过weak_ptr访问对象，典型的用法是通过lock()成员函数来获取shared_ptr，进而使用对象。

```cpp
#include <iostream>
#include <string>
#include <memory>

int main()
{
    // Test();
    std::shared_ptr<int> sh = std::make_shared<int>();
    //与一个 shared_ptr 绑定
    std::weak_ptr<int> w(sh);
    //变出 shared_ptr
    std::shared_ptr<int> another = w.lock();
    std::cout << "weak_ptr所观察的shared_ptr的资源是否已经释放: " << w.expired() << std::endl;
    return 0;
}
```

　　注意上面的代码用C++11之编译不通过，编译时需要指定C++11，编译器。

　　下面用weak_ptr解决循环引用问题。

```cpp
#include <iostream>
#include <string>
#include <memory>

using namespace std;

class Children;
class Parent
{
public:
    ~Parent() { cout << "Parent destructor" << endl; }

    weak_ptr<Children> children_;
};

class Children
{
public:
    ~Children() { cout << "Children destructor" << endl; }

    weak_ptr<Parent> parent_;
};

void Test()
{
    shared_ptr<Parent> pParent(new Parent());
    shared_ptr<Children> pChildren(new Children());

    if (pParent && pChildren)
    {
        pParent->children_ = pChildren;
        pChildren->parent_ = pParent;
    }

    cout << "pParent use_count: " << pParent.use_count() << endl; //1
    cout << "pChildren use_count: " << pChildren.use_count() << endl; //1
}

int main()
{
    Test();
    return 0;
}
```

　　这下Test()函数退出后会调用析构函数。

1. make_shared要优于使用new，make_shared可以一次将需要的内存分配好
2. std::shared_ptr的大小是原始指针的两倍，因为它的内部有一个原始指针指向资源，同时有个指针指向引用计数