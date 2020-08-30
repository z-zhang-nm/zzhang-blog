---
title: "声明全局std命名空间为什么是一种不好的行为"
date: 2020-08-26T11:39:22+08:00
categories:
- category
- subcategory
tags:
- tag1
- tag2
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[链接](https://stackoverflow.com/questions/1452721/why-is-using-namespace-std-considered-bad-practice)
<!--more-->
　　假设如下情况：在代码中使用了两个库Foo和Bar：
```cpp
using namespace foo;
using namespace bar;
```

　　刚开始只调用Foo作用域中的Blah函数和Bar作用域中的Quux函数，一切正常。
```cpp
#include <iostream>

namespace Foo {
void Blah(int x) {}
}  // namespace Foo

namespace Bar {
void Quux(int x) {}
}  // namespace Bar

using namespace Foo;
using namespace Bar;

int main() {
  Blah(1);
  Quux(1);
}
```

　　但是某一天Foo库升级到了2.0版本，恰巧它提供了一个Quux函数，且参数恰巧与Bar中的Quux函数一样，那么全局作用域下关于Quux函数就出现了冲突，会编译出错：`error: call of overloaded "Quux(int)" is ambiguous`。
```cpp
namespace Foo {
void Blah(int x) {}
void Quux(int x) {}
}  // namespace Foo
```

　　还有一种更糟糕的情况，即两个Quux函数参数不一样，那么在调用Quux函数时并不会出现冲突，而是会调用参数类型最匹配的那一个，这会导致程序出现一些未知行为。
```cpp
#include <iostream>

namespace Foo {
void Blah(int x) {}
void Quux(double x) {}
}  // namespace Foo

namespace Bar {
void Quux(int x) {}
}  // namespace Bar

using namespace Foo;
using namespace Bar;

int main() {
  Blah(1);
  Quux(1);
  Quux(1.0);
}
```

　　std空间有大量的标识符，其中许多是很常见的比如list,sort,string,iterator等，这些很可能出现在其它代码中。