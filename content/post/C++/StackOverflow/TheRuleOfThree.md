---
title: "TheRuleOfThree"
date: 2020-09-09T13:30:54+08:00
categories:
- C++
- StackOverflow
tags:
- 拷贝构造函数
- 拷贝赋值操作符
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[链接](https://stackoverflow.com/questions/4172722/what-is-the-rule-of-three)
<!--more-->
> Value semantics is the programming style, or the way of thinking, where we focus on values that are stored in the objects rather than objects themselves.

> C++ supports both value semantics and reference semantics. Value semantics lets us pass objects by value instead of just passing references to objects. In C++, value semantics is the default, which means that when you pass an instance of a class or struct, it behaves in the same way as passing an int, float, or any other fundamental type.To use reference semantics, we need to explicitly use references or pointers.

　　C++将用户自定义的类型看做**Value semantics**，这意味着在进行拷贝时仅仅是值拷贝，看下面这个简单的例子：
```cpp
class person
{
    std::string name;
    int age;

public:

    person(const std::string& name, int age) : name(name), age(age) {}
};

int main()
{
    person a("Bjarne Stroustrup", 60);
    person b(a);   // What happens here?
    b = a;         // And here?
}
```

　　main函数中使用了两种方式进行person对象的拷贝：(1) `person b(a)`执行类的拷贝构造函数(b还未构造完毕) (2) `b = a`执行类的拷贝赋值运算操作(注意b是一个已经构造完毕的person对象)。

　　由于person类即没有声明拷贝构造函数也没有声明拷贝赋值运算操作(也没有声明析构函数)，C++编译器会隐式定义这两个函数，就像下面这样：
```cpp
//copy constructor
person(const person &that) : name(that.name),age(that.age) {}
//copy assignment operator
person &operator=(const person &taht) {
    name = that.name;
    age = that.age;
    return *this;
}
//destructor
~person() {} //do nothing
```

　　这两个默认的函数并没有什么问题，是因为**并没有在类的构造函数中申请任何资源**。那么当我们在构造函数中申请了资源时会发生什么？
```cpp
class person
{
    char* name;
    int age;

public:

    // the constructor acquires a resource:
    // in this case, dynamic memory obtained via new[]
    person(const char* the_name, int the_age)
    {
        name = new char[strlen(the_name) + 1];
        strcpy(name, the_name);
        age = the_age;
    }

    // the destructor must release this resource via delete[]
    ~person()
    {
        delete[] name;
    }
};
```

　　拷贝类对象意味着需要拷贝它的成员变量，但是在拷贝`name`成员变量时，仅仅拷贝了它的值，即一个指针(地址)，而不是指针指向的地址存放的字符串。这会导致如下几个问题：
1. 改变对象a的`name`值会影响对象b
2. 当对象b被正确销毁时，对象a的`name`成了野指针，在销毁对象a时会出现未定义的行为(undefined behavior)
3. 由于拷贝赋值操作没有考虑`name`执行拷贝赋值操作之前的值，会引起内存泄漏

　　默认的拷贝构造函数和拷贝赋值操作会造成如上几个问题，因此需要显示定义这两个函数去进行**深拷贝**。
```cpp
// copy constructor
person(const person& that)
{
    name = new char[strlen(that.name) + 1];
    strcpy(name, that.name);
    age = that.age;
}

// copy assignment operator
person& operator=(const person& that)
{
    if (this != &that)
    {
        delete[] name;
        // This is a dangerous point in the flow of execution!
        // We have temporarily invalidated the class invariants,
        // and the next statement might throw an exception,
        // leaving the object in an invalid state :(
        name = new char[strlen(that.name) + 1];
        strcpy(name, that.name);
        age = that.age;
    }
    return *this;
}
```

　　为了避免内存泄露，必须首先释放`name`之前指向的内存空间，同时需要避免进行自拷贝，因为`this->name`与`that.name`是同一个指针，`delete[] name`会释放自身的内存。

　　上面的拷贝赋值操作可能存在如下问题：即当内存资源耗尽时不能再申请空间，此时new操作会报错，而此时已经删除了之前的`name`值，一个可行的解决方式是额外定义一个局部变量，如下：
```cpp
// copy assignment operator
person& operator=(const person& that)
{
    char* local_name = new char[strlen(that.name) + 1];
    // If the above statement throws,
    // the object is still in the same state as before.
    // None of the following statements will throw an exception :)
    strcpy(local_name, that.name);
    delete[] name;
    name = local_name;
    age = that.age;
    return *this;
}
```

　　一个更加鲁邦的写法是**[copy-and-swap idiom](https://stackoverflow.com/questions/3279543/what-is-the-copy-and-swap-idiom)**。

　　当一些资源不能或不应该被拷贝时，比如文件句柄，应该将拷贝构造函数和拷贝赋值操作声明为私有成员函数，或者使用C++11特性，将其声明为`deleted`。
```cpp
// 1
private:
    person(const person& that);
    person& operator=(const person& that);
// 2
person(const person& that) = delete;
person& operator=(const person& that) = delete;
```

# The rule of three
　　**If you need to explicitly declare either the destructor, copy constructor or copy assignment operator yourself, you probably need to explicitly declare all three of them.**

　　C++11之后，类中多了两个特殊成员函数：移动构造函数和移动赋值函数，因此变为**The rule of five**：
```cpp
class person
{
    std::string name;
    int age;

public:
    person(const std::string& name, int age);        // Ctor
    person(const person &) = default;                // Copy Ctor
    person(person &&) noexcept = default;            // Move Ctor
    person& operator=(const person &) = default;     // Copy Assignment
    person& operator=(person &&) noexcept = default; // Move Assignment
    ~person() noexcept = default;                    // Dtor
};
```
