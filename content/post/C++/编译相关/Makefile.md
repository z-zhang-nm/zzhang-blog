---
title: "Makefile"
date: 2021-05-31T16:26:49+08:00
categories:
- C++
- 编译
tags:
- makefile
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
makefile带来的好处是——自动化编译
<!--more-->
编译时，源文件首先会生成中间目标文件，链接时，中间目标文件会合成可执行文件；编译时主要检查程序语法、函数与变量声明的正确性，链接时主要链接函数和全局变量。

make命令执行时需要一个Makefile文件以告诉make命令需要怎样编译和链接程序，下面粗略介绍一下其规则：
```
target ... : prerequisites ...
             command
             ...
             ...
```

target就是一个目标文件，可以是中间目标文件也可以是执行文件，prerequisites就是要生成target所需要的文件或目标，command就是make需要执行的命令（任意Shell命令）；即target这一个或多个目标文件依赖于prerequisites中的文件，其生成规则定义在command中，若prerequisites中有一个以上的文件比target新的话，command命令就会被执行，这就是Makefile中最核心的内容。

# 1 一个示例说明makefile的概貌
## 1.1 书写规则
以一个示例来说明Makefile的书写规则：
1. 如果工程未被编译过，那么所有C文件都要编译并被链接
2. 如果某几个C文件被修改，只需要编译被修改的文件并链接目标程序
3. 如果头文件被更改，只需要编译引用了这个头文件的C文件

Makefile如下：
```
edit : main.o kbd.o command.o display.o insert.o \
       serach.o files.o utils.o
  cc -o edit main.o kbd.o command.o display.o \
  insert.o serach.o files.o utils.o
main.o : main.c defs.h
  cc -c main.c
kbd.o : kbd.c defs.h command.h
  cc -c command.c
command.o : command.c defs.h command.h
  cc -c command.c
display.o : display.c defs.h buffer.h
  cc -c display.c
insert.o : insert.c defs.h buffer.h
  cc -c insert.c
search.o : search.c defs.h buffer.h
  cc -c search.c
files.o : files.c defs.h buffer.h command.h
  cc -c files.c
utils.o : utils.c defs.h
  cc -c utils.h
clean:
  rm edit main.o kbd.o command.o display.o insert.o \
  serach.o files.o utils.o
```

命令操作行要以一个Tab作为开头，clean不是一个文件，是一个动作名字，其冒号后面什么也没有，要执行这个命令，需要在make命令后显示指出这个命令的名字。

## 1.2 make命令是如何工作的
1. 在当前目录下找名为"Makefile"或"makefile"的文件
2. 如果找到，会在其中找第一个target，上面的例子中为edit，并把它作为最终的目标文件
3. 如果edit文件不存在，或是edit后所依赖的`.o`文件修改时间要比edit新，就会执行后面定义的命令来生成edit文件
4. 如果edit所依赖的`.o`文件也存在，那么会在当前文件中找到目标为`.o`文件的依赖性，执行相应的命令（类似函数调用的入栈出栈）
5. 最终，找到C文件和头文件，这些文件当然存在，于是生成对应`.o`文件，最后由`.o`文件生成edit

make会一层一层地去找文件的依赖关系，直到编译出第一个目标文件，过程中若出现错误，比如最后被依赖的文件找不到，make会直接退出并报错。

假如工程已经编译过了，此时修改`file.c`文件，那么根据依赖性，`file.o`会被重新编译，导致其修改时间比edit新，所以edit也会被重新链接。若修改`command.h`，那么`kbd.o, command.o, files.o`都会被重新编译且edit会被重新链接。

## 1.3 使用变量
示例中可以看到edit的规则中`.o`文件的字符串被重复了两次，clean中也重复了一次，假如增加一个新的`.o`文件，需要在这几个地方都加，若工程特别大，makefile也会复杂，就可能会忘掉在某一个地方添加而导致编译失败，因此，为了makefile易于维护可以使用变量。
```
objects=main.o kbd.o command.o display.o insert.o \
        serach.o files.o utils.o
edit: $(objects)
  cc -o edit $(objects)
...
clean:
  rm edit $(objects)
```

此时若需要加入新的`.o`文件，只需要修改objects变量即可。

## 1.4 自动推导
make会自动推导文件及文件依赖关系后面的命令，因此也就没必要去在每一个`.o`文件后面都写上类似的命令，当make看到一个`.o`文件，它就会自动把`.c`文件加在依赖关系中，例如make找到一个`whatever.o`，那么其依赖文件就是`whatever.c`且`cc -c whatever.c`也会被推导出来。
```
objects=main.o kbd.o command.o display.o insert.o \
        serach.o files.o utils.o
edit: $(objects)
  cc -o edit $(objects)
main.o : defs.h
kbd.o : defs.h command.h
command.o : defs.h command.h
display.o : defs.h buffer.h
insert.o : defs.h buffer.h
search.o : defs.h buffer.h
files.o : defs.h buffer.h command.h
utils.o : defs.h

clean:
  rm edit $(objects)
```


## 1.5 清空目标文件的规则
每个makefile都应有清空目标文件（.o和执行文件）的规则，有利于重新编译和保持文件的清洁，一般比较稳健的做法是：
```
.PHONY:clean
clean:
  -rm edit $(objects)
```

`.PHONY`表示clean是个伪目标文件，rm前的小减号表示如果某些文件出现问题，但不要管，继续做后面的事儿。
一般来说**clean都放在文件的最后**，也就不需要这个规则了。

# 2 makefile总述
## 2.1 makefile里有什么
## 2.2 makefile的文件名
## 2.3 引用其它makefile
## 2.4 环境变量MAKEFILES
## 2.5 make的工作方式

# 3 书写规则
## 3.1 规则举例
## 3.2 规则的语法
## 3.3 在规则中使用通配符
## 3.4 文件搜寻
## 3.5 伪目标
## 3.6 多目标
## 3.7 静态模式
## 3.8 自动生成依赖性

# 4 书写命令
## 4.1 显示命令
## 4.2 命令执行
## 4.3 命令出错
## 4.4 嵌套执行make
## 4.5 定义命令包

# 5 使用变量
## 5.1 变量的基础
## 5.2 变量中的变量
## 5.3 变量高级用法
## 5.4 追加变量值
## 5.5 override指示符
## 5.6 多行变量
## 5.7 环境变量
## 5.8 目标变量
## 5.9 模式变量

# 6 使用条件判断
## 6.1 示例
## 6.2 语法

# 7 使用函数
## 7.1 函数的调用语法
## 7.2 字符串处理函数
## 7.3 文件名操作函数
## 7.4 foreach函数
## 7.5 if函数
## 7.6 call函数
## 7.7 origin函数
## 7.8 shell函数

# 8 make的运行
## 8.1 make的退出码
## 8.2 指定makefile
## 8.3 指定目标
## 8.4 检查规则
## 8.5 make的参数

# 9 隐含规则
## 9.1 使用隐含规则
## 9.2 隐含规则一览
## 9.3 隐含规则使用的变量
## 9.4 隐含规则链
## 9.5 定义模式规则
## 9.6 老式风格的后缀规则
## 9.7 隐含规则搜索算法

# 10 使用make更新函数库文件
## 10.1 函数库文件的成员
## 10.2 函数库成员的隐含规则
## 10.3 函数库文件的后缀规则
## 10.4 注意事项
