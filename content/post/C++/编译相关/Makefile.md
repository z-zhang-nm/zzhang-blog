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

`make`命令执行时需要一个`Makefile`文件以告诉`make`命令需要怎样编译和链接程序，下面粗略介绍一下其规则：
```
target ... : prerequisites ...
             command
             ...
             ...
```

`target`就是一个目标文件，可以是中间目标文件也可以是执行文件，`prerequisites`就是要生成`target`所需要的文件或目标，`command`就是`make`需要执行的命令（任意`Shell`命令）；即`target`这一个或多个目标文件依赖于`prerequisites`中的文件，其生成规则定义在`command`中，若`prerequisites`中有一个以上的文件比`target`新的话，`command`命令就会被执行，这就是`Makefile`中最核心的内容。

# 1 一个示例说明makefile的概貌

## 1.1 书写规则

以一个示例来说明`Makefile`的书写规则：
1. 如果工程未被编译过，那么所有C文件都要编译并被链接
2. 如果某几个C文件被修改，只需要编译被修改的文件并链接目标程序
3. 如果头文件被更改，只需要编译引用了这个头文件的C文件

`Makefile`如下：
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

命令操作行要以一个`Tab`作为开头，`clean`不是一个文件，是一个动作名字，其冒号后面什么也没有，要执行这个命令，需要在`make`命令后显示指出这个命令的名字。

## 1.2 make命令是如何工作的

1. 在当前目录下找名为`Makefile`或`makefile`的文件
2. 如果找到，会在其中找第一个`target`，上面的例子中为`edit`，并把它作为最终的目标文件
3. 如果`edit`文件不存在，或是edit后所依赖的`.o`文件修改时间要比`edit`新，就会执行后面定义的命令来生成`edit`文件
4. 如果`edit`所依赖的`.o`文件也存在，那么会在当前文件中找到目标为`.o`文件的依赖性，执行相应的命令（类似函数调用的入栈出栈）
5. 最终，找到C文件和头文件，这些文件当然存在，于是生成对应`.o`文件，最后由`.o`文件生成edit

`make`会一层一层地去找文件的依赖关系，直到编译出第一个目标文件，过程中若出现错误，比如最后被依赖的文件找不到，`make`会直接退出并报错。

假如工程已经编译过了，此时修改`file.c`文件，那么根据依赖性，`file.o`会被重新编译，导致其修改时间比`edit`新，所以`edit`也会被重新链接。若修改`command.h`，那么`kbd.o, command.o, files.o`都会被重新编译且edit会被重新链接。

## 1.3 使用变量

示例中可以看到`edit`的规则中`.o`文件的字符串被重复了两次，`clean`中也重复了一次，假如增加一个新的`.o`文件，需要在这几个地方都加，若工程特别大，`makefile`也会复杂，就可能会忘掉在某一个地方添加而导致编译失败，因此，为了`makefile`易于维护可以使用变量。
```
objects=main.o kbd.o command.o display.o insert.o \
        serach.o files.o utils.o
edit: $(objects)
  cc -o edit $(objects)
...
clean:
  rm edit $(objects)
```

此时若需要加入新的`.o`文件，只需要修改`objects`变量即可。

## 1.4 自动推导

`make`会自动推导文件及文件依赖关系后面的命令，因此也就没必要去在每一个`.o`文件后面都写上类似的命令，当`make`看到一个`.o`文件，它就会自动把`.c`文件加在依赖关系中，例如make找到一个`whatever.o`，那么其依赖文件就是`whatever.c`且`cc -c whatever.c`也会被推导出来。
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

每个`makefile`都应有清空目标文件（.o和执行文件）的规则，有利于重新编译和保持文件的清洁，一般比较稳健的做法是：
```
.PHONY:clean
clean:
  -rm edit $(objects)
```

`.PHONY`表示`clean`是个伪目标文件，rm前的小减号表示如果某些文件出现问题，但不要管，继续做后面的事儿，一般来说**clean都放在文件的最后**，也就不需要这个规则了。

# 2 makefile总述

## 2.1 makefile里有什么

1. 显式规则：即如何生成一个或多个目标文件（要生成的文件、文件的依赖性、生成命令）
2. 隐晦规则：`make`的自动推导功能允许简略地书写`makefile`
3. 变量的定义：变量一般都是字符串，类似C语言的宏定义，`makefile`被执行时，变量会扩展到相应的引用位置上
4. 文件指示：1）引用其它`makefile`，类似C语言中的`include` 2）根据某些情况指定`makefile`中的有效部分，类似C语言中的#if 3）定义一个多行的命令，后面讲到
5. 注释：`makefile`中只有行注释，与`Shell`一样，用`#`进行注释，若`makefile`中需要用`#`字符，用反斜杠进行转义`\#`

## 2.2 makefile的文件名

默认情况`make`命令会在当前目录寻找`GNUmakefile, makefile, Makefile`的文件名，建议使用`Makefile`作为文件名，也可以使用其它文件名，此时`make`命令需要显示指定文件名：`make -f/--file <makefile>`

## 2.3 引用其它makefile

`include`关键字可以把其它`makefile`包含进来，被包含的文件会直接替换当前位置。

`make`命令开始时会找到所有`include`的文件并替换，如果文件未指定绝对路径或相对路径的话，会在当前目录下寻找，若当前目录未找到，会在如下几个目录下找：
1. 如果`make`命令执行时指定了`-I`或`--include-dir`参数，会在指定的目录下找
2. 如果`/usr/local/bin/include`或`/usr/include`存在的话，会在其中找

若未找到引用的文件，`make`不会立马退出，而是继续载入其它文件，之后再重试加载这些文件，若还是不行，`make`会出现一条致命信息，若想让`make`忽略无法加载的文件，可以在`include`前加一个减号。

## 2.4 环境变量MAKEFILES

`make`命令对环境变量`MAKEFILES`的处理类似于`include`，这个变量中的值是其它`makefile`，由空格分隔，与`include`不同的是，从环境变量引入的其它`makefile`不会起作用且发生错误`make`也不会理会。
一般不建议使用环境变量，因为定义之后所有的`makefile`都会受到影响，若有时`makefile`出现莫名其妙的错误，那就要看看是不是环境变量捣的鬼。

## 2.5 make的工作方式

`make`命令的执行步骤如下：
1. 读入所有的`makefile`文件
2. 读入被`include`的其它`makefile`
3. 初始化文件中的变量
4. 推导隐晦规则并分析所有规则
5. 为所有的目标文件创建依赖关系链
6. 根据依赖关系决定哪些目标需要重新生成
7. 执行生成命令

# 3 书写规则

规则包含两个部分，一个是依赖关系，一个是生成目标的方法，规则的顺序很重要，makefile只有一个最终目标，第一条规则中的第一个目标为最终目标。

## 3.1 规则举例

```
foo.o: foo.c defs.h
  cc -c -g foo.c
```

1. 文件依赖关系：`foo.o`依赖于`foo.c`和`defs.h`，如果`foo.c`和`defs.h`的文件日期比`foo.o`新，或`foo.o`不存在，那么依赖关系发生
2. 生成命令：说明了如何生成`foo.o`（`foo.c`文件`include`了`defs.h`）

## 3.2 规则的语法

```
targets: prerequisites
  command

或这样写：
targets: prerequisites;command
```

`targets`是文件名，可能有多个，以空格分隔，可以使用通配符；`command`是命令行，若不与`targets`写在一行，必须以`Tab`键开头，若与`targets`写在一行，用分号做为分隔；`prerequisites`是目标所依赖的文件。

## 3.3 在规则中使用通配符

`make`支持三个通配符：`*`、`?`和`...`，波浪号`~`在文件名中也有比较特殊的用途，如`~/test`表示当前用户`$HOME`目录下的`test`目录，`~user/test`表示用户`user`的宿主目录下的`test`目录。

如果文件名中包含通配符，那么需要用转义字符来表示真实的字符。

```
// 删除所有的`[.c]`文件
clean:
  rm -f *.o

// 通配符用在变量中
objects=*.o
```

注意若通配符用在变量中，并不是表示`[*.o]`会展开，它表示`objects`的值就是`*.o`；若需要通配符在变量中展开，可以这样写：

```
objects:=$(wildcard *.o) // 关键字wildcard后面进行介绍
```

## 3.4 文件搜寻

大型工程中的源文件一般会分类存放在不同目录下，当`make`需要去寻找文件的依赖关系时，可以把路径告诉`make`，让其自动去找，`make`默认只会在当前目录去找依赖文件和目标文件，若`Makefile`中指明了特殊变量`VPATH`，在当前目录找不到的情况下，会到指定的目录去找。

```
VPATH=src:../headers
```
`make`会顺序在`src`和`../headers`中进行搜索，目录由冒号分隔（当前目录永远是最高优先搜索的目录）。

指定搜索路径的另一种方法是使用`make`的`vpath`关键字，它的使用方法有如下三种：
1. `vpath <pattern> <directories>`：为符合模式`pattern`的文件指定搜索目录`directories`
2. `vpath <pattern>`：清除符合模式`pattern`的文件的搜索目录
3. `vpath`：清除所有已被设置好了的文件搜索目录

`pattern`需要包含`%`字符，表示匹配零个或若干个字符，例如`%.h`表示所有以`.h`结尾的文件。

`vpath`可以连续使用，以指定不同搜索策略，若先后出现相同的`pattern`，会按`vpath`语句的先后顺序执行搜索。

```
vpath %.c foo
vpath %.c bar

或：

vpath %.c foo:bar
```

## 3.5 伪目标

伪目标不是一个文件，不能和文件名重名，`.PHONY`用来指明一个目标是伪目标，即不管是否有这个文件，这个目标就是伪目标。

可以为伪目标指定依赖文件，且可以作为默认目标，只要将其放在第一个，例如若要生成若干个可执行文件：
```
all: prog1 prog2 prog3
.PHONY: all

prog1: prog1.o utils.o
  cc -o prog1 prog1.o utils.o
prog2: prog2.o
  cc -o prog2 prog2.o
prog3: prog3.o sort.o utils.o
  cc -o prog3 prog3.o sort.o utils.o
```

目标可以成为依赖，伪目标同样可以：
```
.PHONY: cleanall cleanobj cleandiff

cleanall: cleanobj cleandiff
  rm program
cleanobj:
  rm *.o
cleandiff:
  rm *.diff
```

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
