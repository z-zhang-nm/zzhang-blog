---
title: "Pyqt循环按钮点击事件"
date: 2020-07-06T20:14:02+08:00
categories:
- 问题解决
tags:
- pyqt
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
问题：
　　pyqt在使用循环生成按钮，并将按钮链接到响应函数时，点击按钮只响应最后一个事件。


```python
for i in range(5):
    btn = QPushButton(str(i))
    btn.clicked.connect(lambda x:BtnPressed(i))

def BtnPressed(n):
    print("这是第{}个按钮".format(n))
```

解决：
　　偏函数传值

```python
from functools import partical

for i in range(5):
    btn = QPushButton(str(i))
    btn.clicked.connect(partical(BtnPressed, i)) #实时传递数值

def BtnPressed(n):
    print("这是第{}个按钮".format(n))
```