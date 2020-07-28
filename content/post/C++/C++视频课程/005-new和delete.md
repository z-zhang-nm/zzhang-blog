---
title: "005 New和delete"
date: 2020-07-28T21:38:11+08:00
categories:
- C++
- C++视频课程
tags:
- new与delete
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
# new与delete
　　new与delete是C++语法，用于替代C语言中的malloc与free，其作用是动态分配堆内存。

## 1 基础类型
```cpp
//C语言
int *a = (int *)malloc(sizeof(int));
*a = 1;
free(a);

//C++语言
int *b = new int;
*b = 1;
delete b;

int *c = new int(1);
delete c;
```

## 2 数组
```cpp
//C语言
int *p1 = (int *)malloc(sizeof(int) * 10);
free(p1);
//C++语言
int *p2 = new int[10];
delete [] p2;
```

## 3 自定义类
```cpp
class Test{
public:
    Test(int a) {a_ = a;}
    ~Test() {}
private:
    int a_;
};

//C语言
Test *t1 = (Test *)malloc(sizeof(Test)); //构造函数不会执行，只会分配内存大小
free(t1); //析构函数不会执行

//C++语言
Test *t2 = new Test(10); //可以执行构造函数
delete t2; //可以执行析构函数
```

## 4 交叉使用
1. 基础类型可以交叉使用，即malloc申请的内存可以delete释放，new申请的内存可以free释放
2. 基础类型的数组也可以交叉使用
3. 对类对象交叉使用时，malloc和free并不会调用构造函数和析构函数，因此不要交叉使用