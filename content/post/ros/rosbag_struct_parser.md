---
title: "Rosbag Struct Parser"
date: 2020-04-30T10:01:03+08:00
categories:
- ros
tags:
- rosbag
#thumbnailImage: //example.com/image.jpg
---
　　由于rosbag API解析数据需要包含消息结构体的头文件，而不同时期录制的roabag中消息结构可能会变化，若用API进行bag包的解析对不同的结构需要写不同的代码，因此根据ros官方提供的rosbag存储结构([Format](http://wiki.ros.org/Bags/Format/2.0))，对rosbag的结构进行解析。
<!--more-->
# Rosbag 结构
　　首先参照官方文档介绍rosbag的数据存储结构，一个bag文件由record序列组成，文件第一行为格式标准版本信息，13个字节（含换行符）。
```
#ROSBAG V2.0
<record 1><record 2>....<record N>
```

## Record format
　　每一个record由以下四个部分组成：
```
<header_len><header><data_len><data>
```
- header_len为4字节小端序整数（低地址到高地址的顺序存放数据的低位字节到高位字节），代表后面header的长度
- header存放长度为header_len的数据，数据格式见[header结构](#header-format)
- data_len为4字节小端序整数，代表后面data的长度
- data存放长度为data_len的数据

## Header format
　　record中的header由一系列`<field_len><field_name>=<field_value>`格式的fields构成，如下：
```
<field1_len><field1_name>=<field1_value><field2_len><field2_name>=<field2_value>...<fieldN_len><fieldN_name>=<fieldN_value>
```
- fieldX_len为４字节小端序整数，代表其后fieldX_name和fieldX_value的长度（包括符号'=’）
- fieldX_name为字符串，代表field的名字
- 不同field的fieldX_value具有不同类型，有可能是字符串、整数等

　　每个header都必定包含一个field_name为op的field，用来表明当前record属于哪个类别，当前版本rosbag结构包括以下几种类别，具体格式见[record类别](#record类别)：
1. Bag header(op=0x03)：存储rosbag中第一个Index data record的偏置、Chunk record的数量和Connection record的数量
2. Chunk(op=0x05)：存储（可能被压缩过的）Connection record和Message data record
3. Connection(op=0x07)：存储ros结点连接的信息，比如topic名字、消息定义文本等
4. Message data(op=0x02)：存储某个连接的序列化消息
5. Index data(op=0x04)：存储某一个连接不同时刻的序列化消息在之前一个Chunk record中的偏置
6. Chunk info(op=0x06)：存储Chunk record的信息，比如偏置、开始结束时间、连接数量等

## **record类别**
　　rosbag中不同类别的record的存储顺序如下所示：
```
<Bag header> (<Chunk>(<Index data>*N))*M <Connection>*K <Chunk info>*M
```
　　N代表前一个Chunk record中连接的数量，M代表rosbag中Chunk record的数量，K代表rosbag中Connection record的数量。

　　Chunk record比较特殊，它的data中包含Connection record和Message data record。

### Bag header
　　rosbag中第一个record，具有4096字节的固定长度，不足4096的部分由空白符（0x20）补充，它的header中包含如下field：
- index_pos：8字节小端序整数，代表rosbag中第一个Index data record的偏置
- conn_count：4字节小端序整数，代表rosbag中Connection record的数量（不含Chunk record中的）
- chunk_count：4字节小端序整数，代表rosbag中Chunk record的数量

### Chunk
　　header中包含如下field：
- compression：字符串类型，代表Chunk record中的数据压缩方法，目前支持`bz2`的压缩方式
- size：4字节小端序整数，代表data未压缩时的大小，压缩后的大小为data_len

### Connection
　　header中包含如下field：
- conn：4字节小端序整数，代表连接的标识号
- topic：字符串类型，代表连接的topic

　　data中包含[Connection header](#connection-header-结构)，它的格式与record中的header一样，由不同的field组成，`topic, type, md5sum, message_definition`必须存在于Connection header中。

#### **Connection header 结构**
　　在ROS中，结点之间直接进行连接，ROS Master只提供一些映射信息，订阅某一topic的结点从发布该topic的结点请求连接，并通过某一协议建立连接，ROS中常用的协议是TCPROS，它使用标准的TCP/IP sockets。

　　TCPROS subscriber 会发送如下field:
- message_definition：消息定义文本
- callerid：发送消息的结点名字
- topic：订阅的topic名字
- md5sum：消息类型的md5sum
- type：消息类型

　　TCPROS publisher连接成功时返回如下field：
- md5sum： 消息类型的md5sum
- type：消息类型

### Message data
　　header中包含如下field：
- conn：4字节小端序整数，代表连接标识号
- time：8字节小端序整数，代表接收消息的时间戳

　　data中存储序列化的消息序列。

　　序列化的数据存储时是按照定义中的顺序存放的，存储string和数组时会多占用4个字节记录string的长度和数组的大小。

　　下面是std_msgs的大小：
- bool : 1
- int8 : 1
- uint8 : 1
- int16 : 2
- uint16 : 2
- int32 : 4
- uint32 : 4
- int64 : 8
- uint64 : 8
- float32 : 4
- float64 : 8
- time : 8(int, int)
- duration : 8(int, int)
- string : 0

　　怎么定位到Message data Record的位置？
> 遍历每一个Index data Record，根据header中记录的Connection ID确定topic，根据Index data Record位置定位到属于哪一个chunk，记录chunk的起始位置，然后遍历data，得到每条消息的时间戳和在chunk中偏置位置，根据`chunk起始位置+偏置位置`定位到记录这条消息的Message data Record在rosbag中的偏置位置。

### Index data
　　header中包含如下field：
- ver：4字节小端序整数，代表记录index data的格式版本
- conn：4字节小端序整数，连接标识号
- count：4字节小端序整数，代表当前连接在之前一个Chunk record中的Message data record的数量

　　当前data记录版本ver为1，data包括不同时刻消息在前一个Chunk record中的偏置：
- time：8字节小端序整数，接收消息的时间戳
- offset：4字节小端序整数，消息在前一个Chunk record中的偏置

### Chunk info
　　header中包含如下field：
- ver：4字节小端序整数，代表记录chunk info data的格式版本
- chunk_pos：8字节小端序整数，代表Chunk record在rosbag中的偏置
- start_time：8字节小端序整数，代表Chunk record中最早接收消息的时间戳
- end_time：8字节小端序整数，代表Chunk record中最晚接收消息的时间戳
- count：4字节小端序整数，代表Chunk record中Connection record的数量

　　当前data记录版本ver为1，data包括不同连接在当前Chunk record中Message data record的数量：
- conn：4字节小端序整数，代表连接标识号
- count：4字节小端序整数，当前连接在当前Chunk record中消息的数量

# 实例

## 结构
`<Bag header>[(<Chunk>(<Index data>*M))*N][<Connection>*K][<Chunk info>*N]`

## Bag header(op=0x03)
`<header_len=69> <field1_len=16><field1_name=chunk_count>=<field1_value=30> <15><conn_count>=<124> <18><index_pos>=<23588957> <4><op>=<3> <data_len=4027><data>`

`<header_len=69> <field1_len=16><field1_name=chunk_count>=<field1_value=1> <15><conn_count>=<1> <18><index_pos>=<112441> <4><op>=<3> <data_len=4027><data>`

## Chunk(op=0x05)
`<header_len=41> <field1_len=16><field1_name=compression>=<field1_value=none> <4><op>=<5> <9><size=787020> <data_len=787020><data>`

`<header_len=41> <field1_len=16><field1_name=compression>=<field1_value=none> <4><op>=<5> <9><size=105400> <data_len=105400><data>`

## Index data(op=0x04)
`<header_len=47> <field1_len=9><field1_name=conn>=<field1_value=0> <10><count>=<1> <4><op>=<4> <8><ver>=<1> <data_len=12><data>`

`<header_len=47> <field1_len=9><field1_name=conn>=<field1_value=0> <10><count>=<235> <4><op>=<4> <8><ver>=<1> <data_len=2820><data>`

## Connection(op=0x07)
`<header_len=83> <field1_len=9><field1_name=conn>=<field1_value=0> <4><op>=<7> <58><topic>=</longitudinal_controller_desay_cfg/parameter_updates> <data_len=1077> <field1_len=43><field1_name=callerid>=<field1_value=/longitudinal_controller_desay_cfg> <10><latching>=<1> <39><md5sum>=<958f16a05573709014982821e6822580> <872><message_definition>=<...> <58><topic>=</longitudinal_controller_desay_cfg/parameter_updates> <31><type>=<dynamic_reconfigure/Config>`

`<header_len=52> <field1_len=9><field1_name=conn>=<field1_value=0> <4><op>=<7> <27><topic>=</fusion/obstacle_list> <data_len=5230> <field1_len=16><field1_name=callerid>=<field1_value=/pb2ros> <10><latching>=<0> <39><md5sum>=<438bf5efdcd3ff12e3b317344780e529> <5078><message_definition>=<...> <27><topic>=</fusion/obstacle_list> <36><type>=<nullmax_msgs/FusedObstacleArray>`

## Chunk info(op=0x06)
`<header_len=100> <field1_len=18><field1_name=chunk_pos>=<field1_value=4117> <10><count>=<96> <17><end_time>=<> <4><op>=<6> <19><start_time>=<> <8><ver>=<1> <data_len=8><data>`

`<header_len=100> <field1_len=18><field1_name=chunk_pos>=<field1_value=4117> <10><count>=<1> <17><end_time>=<(secs)+(nsecs)> <4><op>=<6> <19><start_time>=<> <8><ver>=<1> <data_len=8><data>`

# Rosbag数据结构解析

## 数据结构
　　首先需要定义一个存储rosbag数据的**数据结构**Bag，初步判断其中需要包括：记录record基本信息（offset,header_len, data_len）的结构Record，存储各个Record的record_list_数组，存储消息结构的数据结构。

## 提取Record基本信息
> 一个字节八个比特,就是八个二进制位，四个二进制数最大表示为15,就是一个16进制数,所以八位可以表示成两个16进制的数，即一个字节为两个用两个16进制数表示

　　读取文件时需要借助字符数组作为Buffer，其大小一般为4*1024=[4096](https://stackoverflow.com/questions/236861/how-do-you-determine-the-ideal-buffer-size-when-using-fileinputstream)个字节。

　　为了方便后续进行record的解析，首先遍历rosbag文件，提取各个record的基本信息，包括各个record的起始位置，header length和data length。解析时使用C++标准库的文件流`ifstream`。
1. 定位到文件末尾，记录文件末尾位置，作为遍历结束条件
2. 跳过rosbag第一行的13个字符，定位到第一个record(Bag header)的位置，开始遍历record
   1. 记录record的offset位置
   2. 读取4个字节，得到header_len
   3. 从当前位置向前定位header_len个字节
   4. 读取4个字节，得到data_len
   5. 从当前位置向前定位data_len个字节
   6. 将当前record放入record_list_
3. 定位到文件开始位置

## 解析Record Header数据
　　[提取Record基本信息](#提取record基本信息)中已经得到rosbag中每一个record的基本信息，下面首先对每一个record的header进行解析，header的格式见[Header Format](#header-format)一节。

　　这里需要解析header的数据，因此需要一个新的**数据结构**存储header data，由于header的格式为`<len><name>=<value>`，需要记录每一对name和value的数据对，由此哈希map比较合适。
1. 定位到record.offset+4的位置，即header data开始的位置
2. 由于Buffer大小为4096个字节，header_len可能大于4096，因此需要先确定读取的次数
3. 读取header data并转换为string格式，接下来循环解析这个字符串
   1. 首先读取4个字节，得到field_len
   2. 截取field_len长度的子串，并找到字符`=`的位置
   3. `=`前面为field_name，后面为field_value
   4. 将键值对加入Header map

　　利用Record Header解析函数解析第一个record，即Bag header record，得到rosbag中Chunck record和Connection Record的个数。

## 消息结构解析

### Record选取
　　消息定义在rosbag中有两种record可以获取，即Chunck record和Connection record，由[rosbag结构实例](#结构)一节可以知道rosbag中records的排列是有顺序的，由于Chunck中的数据可能是被压缩过的且其与Index data record交叉排列，所以选择Connection record作为消息结构解析record。

### 存储数据结构选取
　　rosbag中含有不同topic的消息，每一个topic中包含不同的消息，消息类型包括ros基本消息类型和用户自定义类型，消息可以包含多个层级，比如`header.stamp.secs`代表时间戳中的秒，不同消息的结构深度不同，因此考虑使用**树结构**作为**存储消息结构的数据结构**。

　　树结构应该包含的内容：
1. 每一个消息都会有名字name，对应的会有类型type，比如`string frame_id`，`frame_id`为名字，`string`为类型
2. 消息可能由其它消息组成，比如`Header`由`uint32 seq, time stamp, string frame_id`组成，因此一个消息结点可能有数个子结点`child`，存储在`TreeNode *`数组中
3. 消息结点也会有一个父结点`parent`
4. 消息可能是一个数组`array`，也应该有数组大小`array_size`
5. 消息是否是ros基本类型`std_type`，类型大小`size`，若不是基本类型，大小为-1

### 消息结构树的建立
　　对每一个Connection record，由于其data部分的结构也是`<len><name>=<value>`的形式，首先使用Record Header解析函数解析data部分，得到一个个的键值对map，我们需要的是message_definition和type这两个field，解析完成后用这两个field进行消息结构树的建立。
1. message_definition包含了topic中记录的所有消息及其结构，消息之间由多个`=`组成的分隔符分割，且第一个分隔符之前的消息定义为topic包含的消息，其它的消息定义为topic消息中用户自定义消息的结构，首先将所有的消息定义字符串分割出来，存入一个数组（消息定义数组）
2. 遍历消息定义数组中的每一个消息块字符串，构建所有子结点，由于遍历时除了可以确定第一个消息块的每个消息结点是根节点的子结点，可以加入根结点的孩子结点数组中，其它消息块的每个消息结点都是根结点的子结点的子结点，由于遍历时还未构建树结构，因此可以先用一个**数据结构**（子消息结构）将每一个消息块的每个消息结点存储起来，最后在构建树的时候从中寻找结点，这个数据结构需要具有能够存储子结点的孩子数组，且要记录这个消息块的类型名字，以便后续构建树的时候可以确定其父结点
   1. 分割字符串的每一行，存入一个数组（具体定义数组），提取时只保留有效的消息定义行，且删除头尾空白符和注释，无效的行包括：
      1. 全是注释的行
      2. 空行
      3. 空白符加注释的行
   2. 若不是根结点的子结点，这个消息块的第一行仅包含类型消息，例如`MSG: nullmax_msgs/LkaLane`，提取出`/`后的类型作为子消息结构的类型名字
   3. 对每一行有效消息，生成一个子结点
      1. 判断是否是数组类型，分为固定大小数组和动态数组，区别是`[]`中有无数组大小，若是固定大小数组，提取出数组大小
      2. 提取出类型名和消息名字
      3. 设置是否为数组类型，若不是，数组大小设置为-1
      4. 若为根结点的子结点，将其加入根结点的孩子数组，否则加入子消息结构的孩子数组
   4. 设置每一个结点类型的大小，若不是根结点的子结点，将子消息结构放入一个子消息结构数组中
3. 构建消息树
   1. 对根结点的每一个子结点，若其不是基本类型，从子消息结构数组中进行匹配
   2. 遍历子消息结构数组，若根结点的子节点的类型与子消息结构的类型名字一样，则将子消息结构数组的孩子结点都赋予这个子节点
   3. 对子结点的孩子结点，若不是基本类型且其孩子数组为空，则递归进行第二步
   4. 退出循环
4. 查看消息树
   1. 先打印结点层数个`tab`
   2. 若结点为数组，打印`type[array_size] name`，否则打印`type name`
   3. 结点层数加一
   4. 遍历结点子结点，递归查看

# Load消息代码生成

## 创建包含所有topic的头文件
　　`unistd.h`头文件逐路径创建目录与文件（`structure.h`），并写入`#param once\n`。

## 生成读取不同topic的代码
　　遍历不同topic的消息结构树，生成读取topic消息的代码，需要生成的文件包括CMakeLists、以topic名字命名的头文件和cpp代码文件，注意需要将topic中`/`替换为`_`，这些文件需要放在与`structure.h`同一目录下。

　　首先在`structure.h`中加入一行包含当前topic的头文件代码，例如`#include "fusion_obstacle_list.h"`。

### 生成头文件
　　头文件中包括topic的完整消息结构定义(struct)、LoadData函数和OutputData函数的声明。每个头文件的前四行内容都是固定的，以`fusion_obstacle_list`为例,如下：
```cpp
#param once
#include "public_header.h"
#define FUSIONOBSTACLELIST
namespace fusion_obstacle_list{
```

　　遍历消息树根结点的所有子结点，自下向上生成消息结构体（后序遍历）：
1. 递归遍历子结点的子结点，直到到达叶子结点
2. 若当前结点为基本类型，不用生成消息结构体，跳过
3. 将当前节点的类型加入已生成列表，确保不会重复生成相同的结构体
4. 头文件内容添加`struct 结点消息类型_type{\n`
5. 遍历当前结点的所有子结点：
   1. 头文件内容加入tab空格字符串
   2. 若子结点为数组：
      1. 若子结点为基本类型：
         1. 若数组大小为-1，用`std::vector`
         2. 若数组大小不为-1，用c风格数组
      2. 若子结点为自定义类型，结点类型后面加上`_type`：
         1. 若数组大小为-1，用`std::vector`
         2. 若数组大小不为-1，用c风格数组
   3. 若子结点类型为`string`，类型需要加上`std::`
   4. 若子结点类型为`time`，变为`time_ros`
   5. 若子结点类型不是基本类型，需要加上`_type`
6. 最后头文件内容加上`};\n`

　　接下来生成topic消息结构体，统一命名为`objet`，头文件内容加上`struct objet{\n`，按照上面第五步的方式处理根结点的所有子节点，并在最后加上`};\n`。

　　头文件内容加上`}\n`与`namespace fusion_obstacle_list{`组成完整命名空间。

　　接下来加入LoadData函数和OutputData函数的声明，参数类型为`<topic名字>::object`，如下例子，其中`ToolStream`为public_header中的类，用于数据的输入和输出：
```cpp
void LoadData(ToolStream &ss,fusion_obstacle_list::object &value);
void OutputData(fusion_obstacle_list::object &value);
```

### 生成cpp文件
　　首先增加头文件包含，例如：
```cpp
#include "fusion_obstacle_list.h"
```

#### LoadData函数实现
　　加入LoadData函数声明行：
```cpp
void LoadData(ToolStream &ss,fusion_obstacle_list::object &value){
```

　　用数组`load_prefix`存放当前遍历到的树的结点名字，并向数组中放入`value`，遍历根结点的子结点：
1. 遍历`load_prefix`数组，生成从根结点到当前结点的结构字符串，由`.`连接
2. 若当前结点为基本类型且不是数组：
   1. 若类型为string，序列化字符串会多四个字节来存放字符串的长度，首先需要读取字符串大小，然后resize结点消息字符串大小
   2. 生成读取消息行`ss >> <prefix+name>;\n`
3. 若当前结点为基本类型且是数组，考虑到多维数组，读取数组大小的变量名需要加上序号标志来进行区分
   1. 序列化字符串存储**动态**数组也会多四个字节存放数组的大小，因此需要首先读取数组大小，resize结点消息字符串大小
   2. 若是固定长度数组，直接获取数组大小
   3. 生成读取消息循环
4. 若当前结点为自定义类型且是数组
   1. 与3的处理方式基本一样，不过由于并非基本类型，所以树结构还没到叶子结点，所以需要继续递归遍历，遍历前需要将当前变量名加数组索引名字加入`load_prefix`数组
   2. 遍历结束后将其弹出
   3. 加上`}\n`闭合循环
5. 若当前结点为自定义类型且不是数组
   1. 将当前结点变量名加入`load_prefix`数组
   2. 递归遍历结点子结点
   3. 弹出当前变量名

　　加入`}\n`闭合函数名义。

```cpp
//string
int string_size_0(0);
ss >> string_size_0;
value.header.frame_id.resize(string_size_0);
ss >> value.header.frame_id;
//基本类型
ss >> value.header.seq;
//自定义类型
ss >> value.center_lane.position_parameter_c0;
//数组
int array_size_0(0);
ss >> array_size_0;
value.center_lane.quality_score.resize(array_size_0);
for(int index_0 = 0;index_0 < array_size_0;++index_0){
 ss >> value.center_lane.quality_score[index_0].distance;
 ss >> value.center_lane.quality_score[index_0].score;
}
```

#### OutputData函数实现
　　与LoadData函数类似，不过将数据流读取变为cout输出而已。

### 生成CMakeList文件
　　加入如下固定内容即可：
```
SET(CMAKE_BUILD_TYPE "Debug")
SET(CMAKE_CXX_FLAGS_DEBUG "$ENV{CXXFLAGS}    -O0 -Wall -g2 -ggdb") 
SET(CMAKE_CXX_FLAGS_RELEASE "$ENV{CXXFLAGS} -O3 -Wall")
cmake_minimum_required(VERSION 3.2)
add_compile_options(-std=c++11)
project(bag_structer_parse)
file(GLOB sources *.cpp)
add_library(bag_structer SHARED ${sources})
```
