---
title: "遍历string中的单词"
date: 2020-08-18T15:26:27+08:00
categories:
- C++
- StackOverflow
tags:
- string
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
[链接](https://stackoverflow.com/questions/236129/how-do-i-iterate-over-the-words-of-a-string)
<!--more-->
　　给一个包含单词和空白符的string，提取其中的单词。
```cpp
#include <iostream>
#include <sstream>
#include <string>

using namespace std;

int main()
{
    string s = "Somewhere down the road";
    istringstream iss(s);

    string subs;
    while(iss >> subs){
        cout << "Substring: " << subs << endl;
    }

    return 0;
}
```

## C++输入输出流
　　C++中输入输出流分为三种：
1. 基于控制台的I/O
2. 基于文件的I/O
3. 基于字符串的I/O

### 基于控制台的I/O(#include <iostream>)
- istream : 从**流**中读取
- ostream : 写入**流**中
- iostream : 对流进行读写，从istream和ostream派生

### 基于文件的I/O(#include <fstream>)
- ifstream : 从文件中读取，从istream派生
- ofstream : 写入文件中，从ostream派生
- fstream : 对文件进行读写，从iostream派生

### 基于字符串的I/O(#include <sstream>)
- istringstream : 从string对象读取，从istream派生
- ostringstream : 写入string对象，从ostream派生
- stringstream : 对string对象进行读写，从iostream派生


　　有没有更优雅的方法？可以使用C++ STL标准库方法。

# STL标准库
```cpp
#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <iterator>

int main() {
    using namespace std;
    string sentence = "And I feel fine...";
    istringstream iss(sentence);
    copy(istream_iterator<string>(iss),
         istream_iterator<string>(),
         ostream_iterator<string>(cout, "\n"));
}
```
　　

　　也可以直接放入容器中。

```cpp
//方法一
vector<string> tokens;
copy(istream_iterator<string>(iss),
     istream_iterator<string>(),
     back_inserter(tokens));
//方法二
vector<string> tokens{istream_iterator<string>{iss},
                      istream_iterator<string>{}};
```

　　这种方式只能处理空白符，若单词以其它分隔符分割，就不能正确提取。
```cpp
#include <string>
#include <sstream>
#include <vector>
#include <iterator>

template <typename Out>
void split(const std::string &s, char delim, Out result) {
    std::istringstream iss(s);
    std::string item;
    while (std::getline(iss, item, delim)) {
        *result++ = item;
    }
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, std::back_inserter(elems));
    return elems;
}
```