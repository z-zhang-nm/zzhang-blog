---
title: "ProblemsSolution"
date: 2020-09-27T18:09:36+08:00
categories:
- 问题解决
tags:
- 模块调用
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---

<!--more-->
　　python中调用不同路径下的模块时需要在调用代码的文件开始部分引入模块所在路径，一般情况下只需要将工程路径在main.py中最开始引入即可，这样就能在不同模块中相互调用，如下：
```
project
-- main.py
-- A
    -- a.py
-- B
    -- b.py
```
　　在main.py中加入如下代码：
```python
import sys
import os
PROJECT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(PROJECT_PATH)
```

　　需要注意的是对于python2，需要在被调用模块所在文件夹中加入内容为空的`__init__.py`文件。