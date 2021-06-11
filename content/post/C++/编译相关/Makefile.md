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

`make`支持多目标，当多个目标同时依赖于一个文件且其生成的命令大致相同，就可以将它们合并，目标生成命令中需要用自动化变量`$@`，关于自动化变量，将在后面介绍：
```
bigoutput littleoutput: text.g
  generate text.g -$(subst output,,$@)>$@
```

上面的规则等价于：
```
bigoutput: text.g
  generate text.g -big>bigoutput
littleoutput: text.g
  generate text.g -little>littleoutput
```

其中`-$(subst output,,$@)`中的`$`表示执行一个函数，函数名为`subst`，后面的为参数，关于函数后面再具体介绍，`$@`表示目标的集合，就像一个数组，依次取出目标，并执行命令。

## 3.7 静态模式

静态模式可以更容易地定义多目标的规则，其语法如下：
```
<targets ...>: <target-pattern>:<prereq-patterns ...>
  <commands>
  ...
```

其中`targets`定义了一系列的目标文件；`target-pattern`指明了`targets`的模式，例如`%.o`表明`targets`集合中都是以`.o`结尾的；`prereq-patterns`是目标的依赖模式，它对`target-pattern`形成的模式再进行一次依赖目标的定义，例如`%.c`表明取`target-pattern`模式中的`%`并为其加上`.c`结尾，形成新的集合。

```
objects=foo.o bar.o
all: $(objects)
$(objects): %.o: %.c
  $(CC) -c $(CFLAGS) $< -o $@
```

其中自动化变量`$<`和`$@`分别表示依赖目标集（foo.c bar.c）和目标集（foo.o bar.o），上面的规则等价于：
```
foo.o: foo.c
  $(CC) -c $(CFLAGS) foo.c -o foo.o
bar.o: bar.c
  $(CC) -c $(CFLAGS) bar.c -o bar.o
```

再举一个静态模式更灵活用法的例子：
```
files=foo.elc bar.o lose.o
$(filter %.o,$(files)): %.o: %.c
  $(CC) -c $(CFLAGS) $< -o $@
$(filter %.elc,$(files)): %.elc: %.el
  emacs -f batch-byte-compile $<
```

其中`$(filter %.o,$(files))`表示调用`filter`函数进行过滤，只要`files`中模式为`%.o`的内容。

## 3.8 自动生成依赖性

如果`main.c`中有一句包含语句`#include "defs.h"`，那`main.o`的依赖关系如下：
```
main.o: main.c defs.h
```

如果是一个比价大的工程，就必须知道哪些文件包含了哪些头文件，且加入和删除头文件时也要小心修改makefile，为了避免这种繁杂又易出错的做法，可以用编译器的`-M`选项，它可以自动寻找源文件中包含的头文件并生成一个依赖关系：
```
// 执行命令
cc -M main.c
// 输出
main.o: main.c defs.h
```

注意若使用`GNU`的`C/C++`编译器，需要使用`-MM`，不然会把一些标准的头文件也包含进来：
```
gcc -M main.c
// 输出
main.o: main.c defs.h /usr/include/stdio.h ...

gcc -MM main.c
// 输出
main.o: main.c defs.h
```

那么如何将编译器的这个功能应用于`makefile`呢？`GNU`组织建议把编译器为每一个源文件自动生成的依赖关系放到一个文件中，即为每一个`name.c`文件都生成一个`name.d`的`makefile`文件，`.d`文件存放对应`.c`文件的依赖关系；那么就可以让make自动更新或生成`name.d`文件并将其包含在主`makefile`中。

下面是一个生成`.d`文件的模式规则
```
%.d: %.c
  @set -e; rm -f $@; \
  $(CC) -MM $(CPPFLAGS) $< > $@.$$$$; \
  sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
  rm -f $@.$$$$
```

其中，`rm -f $@`表示删除所有目标，即`.d`文件；第二行表示为每个依赖文件（`$<`，即`.c`文件）生成依赖关系文件，`$$$$`表示一个随机编号，假设有一个`name.c`文件，那么可能会生成`name.d.12345`；第三行使用`sed`命令做了一个替换，详见[makefile写法详解](https://www.cnblogs.com/jiangzhaowei/p/5450555.html)和[makefile学习](https://www.cnblogs.com/Liu-Jing/p/8290118.html)。

# 4 书写命令

`make`的命令默认是被标准Shell`/bin/sh`执行的，即环境变量`SHELL`。

## 4.1 显示命令

将`@`字符加到命令行前将不被`make`显示出来，例如：
```
  @echo 正在编译XXX模块...
```

上面的命令将输出`正在编译XXX模块...`字符串，但不会输出命令，若不加`@`字符，`make`将输出：
```
echo 正在编译XXX模块...
正在编译XXX模块...
```

`make`的`-n`或`--just-print`参数表示仅仅显示命令并不执行命令，可以帮助调试`makefile`。

`make`的`-s`或`--slient`参数表示全面禁止命令的显示。

## 4.2 命令执行

若两条命令写在一行上并用分号分隔，表示这前一条命令的结果应用在下一条命令。
```
exec1:
  cd /home/test
  pwd
exec2:
  cd /home/test; pwd
```

上面例子中`exec1`中的`cd`没有作用，`pwd`会打印当前的`makefile`目录，而`exec2`会打印`/home/test`目录。

## 4.3 命令出错

每个命令执行完成后会有一个返回码，若命令返回成功（零），`make`会执行下一条命令，若某个命令出错，`make`就会终止执行当前规则，若命令前有`-`，则会忽略错误，继续执行下一条命令，否则可能会终止所有规则的执行。

`make`的`-i`或`--ignore-errors`参数表明`makefile`中所有的命令都会忽略错误，若`makefile`中某个规则是以`.IGNORE`为目标，那么这个规则中所有命令都会忽略错误。

`make`的`-k`或`--keep-going`参数表明若某规则中的某条命令出错，就终止该规则的执行，但继续执行其它规则。

> 注意规则和命令的区别：规则为`makefile`中的一个个生成规则，命令为规则中需要执行的命令

## 4.4 嵌套执行make

一般不同模块或不同功能的源文件会放在不同的目录中，那就可以在每个目录都写一个该目录的`makefile`，这样会易于维护，方便模块化编译和分离编译。

假设一个子目录名为`subdir`，那么总控`makefile`可以这样写：
```
// MAKE为定义的宏变量，某些情况make需要一些参数，定义为一个变量易于维护
subsystem:
  cd subdir && $(MAKE)
// 等价于
subsyatem:
  $(MAKE) -C subdir
```

总控`makefile`的变量可以传递到下级`makefile`中，但不会覆盖下级`makefile`中的变量，除非指定了`-e`参数：
```
// 向下级传递变量
export <variable ...>
// 禁止向下传递
unexport <variable ...>

// 示例1
export variable = value
// 等价于（1）
variable = value
export variable
// 等价于（2）
export variable:=value
// 等价于（3）
variable:=value
export variable

// 示例2
export variable += value
// 等价于
variable += value
export variable

// 示例3
export //传递所有变量
```

`SHELL`和`MAKEFLAGS`这两个变量不管是否`export`都会向下传递，`MAKEFLAGS`包含了`make`的参数信息，若执行总控`makefile`有参数或上层`makefile`中定义了这个变量，那么`MAKEFLAGS`将是这些参数。

若不想向下级传递参数，可以这样写：
```
subsystem:
  cd subdir && MAKEFLAGS=
```

嵌套执行中若想打印当前工作目录，可以加上`-w`或`--print-directory`参数，注意`-s`会让`-w`失效。

## 4.5 定义命令包

可以为相同的命令序列定义一个变量，以`define`开始，以`endef`结束：
```
define test
<command1>
<command2>
endef
```

# 5 使用变量

变量名字可以包含字符、数字、下划线（可以是数字开头），不应包含`:`、`#`、`=`或是空字符，大小写敏感，为了避免和系统变量冲突，推荐使用首字母大写的变量名。

## 5.1 变量的基础

变量声明时需要给予初值，使用时需要在变量名前加`$`符号且最好使用`()`或`{}`把变量括起来，若要使用`$`符号，需要用`$$`表示。
```
objects=program.o foo.o utils.o
program:$(objects)
  cc -o program $(objects)
$(objects):defs.h
```

变量会在使用它的地方精确地展开，就像`C++`中的宏一样。

## 5.2 变量中的变量

可以使用其它变量的值来构造变量的值，`makefile`中有两种方式。

第一种使用简单的`=`号，等号左侧是变量，右侧是变量的值，右侧变量的值可以定义在文件的任何一处，即可以使用后面定义的值：
```
foo = $(bar)
bar = $(ugh)
ugh = Huh?

all:
  echo $(foo) // 打印 Huh?
```

这种方式可能会有递归定义无限循环的问题，`make`是可以检测出这种错误的：
```
CFLAGS = $(CFLAGS) -O
或：
A = $(B)
B = $(A)
```

第二种方式是使用`:=`操作符，与等号不同的是，这种方法前面的变量不能使用后面的变量，只能使用前面已经定义好的变量：
```
y := $(x) bar // y的值为 bar，而不是foo bar
x := foo
```

> 定义一个值为一个空格的变量

```
nullstring:=
space:=$(nullstring) #end of the line
```

`nullstring`是一个空变量，啥也没有，由于在操作符右侧很难描述一个空格，所以先用一个空变量来表明变量的值开始了，后面跟一个空格，再由注释表示变量定义的终止，这样就定义了一个空格的变量。

注释的这种用法值得注意：
```
dir:=/foo/bar    #directory
```

`dir`变量后面跟了四个空格，若使用这个变量来指定其它目录，如`$(dir)/file`就会出问题。

> 条件变量操作符

```
FOO?=bar
```

上面的例子表示若`FOO`没有被定义，那么变量的值就是`bar`，否则这条语句啥也不做，等价于：
```
ifeq ($(origin FOO), undefined)
  FOO=bar
endif
```

## 5.3 变量高级用法

### 5.3.1 变量值的替换

`$(var:a=b)`或`${var:a=b}`意思是将变量`var`中所有以`a`结尾（结尾指的是空格或结束符）的部分的`a`替换为`b`。

```
foo:=a.o b.o c.o
bar:=$(foo:.o=.c) // bar的值为a.c b.c c.c
```

或者使用静态模式进行替换：
```
foo:=a.o b.o c.o
bar:=$(foo:%.o=%.c) // bar的值为a.c b.c c.c
```

### 把变量的值再当成变量

```
x = y // 注意是 x=y 而不是 x=$(y)
y = z
a:=$($(x)) // 等价于 a:=$(y) 即 a:=z
```

```
x = $(y)
y = z
a:=$($(x)) // 等价于 a:=$($(y)) 即 a:=$(z)
```

```
x=var1
var2:=Hello
y=$(subst 1,2,$(x))
z=y
a:=$($($(z)))
```

上例中，首先将`$($($(z)))`扩展为`$($(y))`，再次扩展为`$($(subst 1,2$(x)))`，而`$(subst 1,2$(x))`的值为`var2`，则再次扩展为`$(var)`即`Hello`。

甚至可以用多个变量组成一个变量的名字：
```
first_second = Hello
a = first
b = second
all = $($(a)_$(b)) // all 的值为 Hello
```

结合变量值替换技术的一个例子：
```
1_objects:=a.o b.o c.o
2_objects:=d.o e.o f.o
sources:=$($(x)_objects:.o=.c)
```

上例中若`$(x)`的值为`1`，那么`sources`的值为`a.c b.c c.c`，若`$(x)`的值为`2`，那么`sources`的值为`d.c e.c f.c`。

> 把变量的值再当成变量的技术也可用在操作符左边

## 5.4 追加变量值

使用`+=`操作符给变量追加值：
```
objects=main.o foo.o bar.o utils.o
objects+=another.o
```

等价于：
```
objects=main.o foo.o bar.o utils.o
objects:=$(objects) another.o // 注意是用的 := 赋值符
```

若变量之前未定义过，那么`+=`会自动变为`=`，若变量之前有定义，那么`+=`会继承定义时的赋值符：
```
variable:=value
variable+=more

// 等价于
variable:=value
variable:=$(variable) more

// 若这样写
variable=value
variable+=more // 会发生变量的递归定义
```

## 5.5 override指示符

若有变量是通过`make`的命令行参数设置的，那么`makefile`中对这个变量的赋值会被忽略，若需要设置这类参数的值，可以使用`override`指示符，也可用于多行变量：
```
override <variable> = <value>
override <variable> := <value>
```

## 5.6 多行变量

使用`define`关键字设置变量的值时可以换行，`define`后面跟变量的名字，重起一行定义变量的值，定义以`endef`关键字结束。

变量的值可以包含函数、命令、文字或其它变量，由于`makefile`中命令需要以`[Tab]`键开头，如果用`define`定义命令变量中没有以`[Tab]`键开头，那么`make`就不会将其认为是命令。
```
define two-lines
echo foo
echo $(bar)
endef
```

## 5.7 环境变量

`makefile`中定义的变量或`make`命令行参数变量会覆盖系统环境变量，若`make`指定了`-e`参数，那么系统环境变量将覆盖`makefile`中定义的变量。

当`make`嵌套调用时，上层`makefile`中定义的变量会以系统环境变量的方式传递到下层`makefile`，默认情况下只有通过命令行设置的变量会被传递，定义在文件中的变量需要使用`export`关键字声明才会传递。

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
