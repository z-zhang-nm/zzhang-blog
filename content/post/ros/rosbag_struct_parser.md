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
　　每一个record有如下格式：
```
<header_len><header><data_len><data>
```
* header_len为４字节little-endian整数（低地址到高地址的顺序存放数据的低位字节到高位字节），代表其后header的长度
* header存放长度为header_len的数据，数据内容见[Header format](#header-format)
* data_len为４字节little-endian整数，代表其后data的长度
* data存放长度为data_len的数据
* 注意Chunk Record比较特殊，它的data中包含另外的Connection Record和Message Data Record
## Header format
　　每一个header由`<len><name>=<value>`的fields序列组成，如下：
```
<field1_len><field1_name>=<field1_value><field2_len><field2_name>=<field2_value>...<fieldN_len><fieldN_name>=<fieldN_value>
```
* fieldX_len为４字节little-endian整数，代表其后fieldX_name和fieldX_value的长度（包括符号'='）
* fieldX_name为字符串，代表field的名字
* 不同field的fieldX_value具有不同类型，有可能是字符串或整数等

　　每一个header都包含一个名字为op的field，用来指定record的类别，包括以下几种类别（按在bag包中首次出现的顺序列出）：
1. Bag header(op=0x03)：存储整个bag包的结构信息：第一个Index Data Record的偏置、Chunk Records和Connection Records的数量
2. Chunk(op=0x05)：存储可能被压缩过的Connection Records和Message Data Records
3. Connection(op=0x07)：存储[ROS connection header](#ros-connection-header)，包括topic名字和消息定义文本
4. Message data(op=0x02)：存储某个Connection Record的序列化消息数据（长度可能为0）
5. Index data(op=0x04)：存储前面chunk record单个connection中消息的索引
6. Chunk info(op=0x06)：存储chunk中消息的信息
### ROS connection header
　　存储建立的连接的元数据，field_name和field_value都是字符串，格式：
```
4-byte length + [4-byte field length + field_name=field_value]*
```
　　TCPROS是供ROS消息和服务端使用的一个传输层，使用标准TCP/IP套接字来传输消息，TCPROS connections包括如下fields：
* TCPROS subscriber 需要发送如下fields:
  * message_definition：全部消息定义的文本
  * callerid：发送消息的节点名字
  * topic：订阅的topic名字
  * md5sum：消息类型的md5sum
  * type：消息类型
  * latching：发布者是否是latching模式（发送最新消息给新的订阅者）
* TCPROS publisher连接成功时返回如下fields：
  * md5sum： 消息类型的md5sum
  * type：消息类型
## Records
### Bag header
　　rosbag的第一个record，具有固定的4096字节的长度，不足4096字节的部分用ASCII空白符(0x20)填充，header包含如下fields：
* index_pos：8字节little-endian整数，代表chunk后第一个record的偏置
* conn_count：4字节little-endian整数，代表Connection Record的数量（不包括Chunk中的）
* chunk_count： 4字节little-endian整数，代表Chunk Record的数量
### Chunk
　　data存储压缩后的Message data Records和Connection Records，header包含如下fields：
* compression：字符串类型，代表数据压缩方法（none或bz2）
* size：4字节little-endian整数，代表未压缩的消息块的大小
### Connection
　　data存储[Connection Header](#ros-connection-header)字符串，connection header一定包含**topic, type, md5sum, message_defination**这几个fields，可以包含**callerid, latching** fields，header包含如下fields：
* conn：4字节little-endian整数，代表连接的ID号
* topic：字符串类型，代表存储消息的topic名字
### Message data
　　data存储序列化的ros messages，header包含如下fields：
* conn：4字节little-endian整数，代表发送消息的连接的ID号
* time：8字节little-endian整数，代表消息接收时间
### Index data
　　data格式取决于header中存储的版本号，当前版本为1，data包含时间戳（8字节little-endian整数）、Message data Record的偏置信息（4字节little-endian整数），header包含如下fields：
* ver：4字节little-endian整数，代表index data record的版本
* conn：4字节little-endian整数，代表连接的ID号
* count：4字节little-endian整数，代表前一个chunk中消息的数量
### Chunk info
　　data格式取决于header中存储的版本号，当前版本为1，data包含连接ID（4字节little-endian整数）、连接中的消息数量（4字节little-endian整数），header包含如下fields：
* ver： 4字节little-endian整数，代表chunk info record的版本
* chunk_pos：8字节little-endian整数，代表chunk record的偏置
* start_time：8字节little-endian整数，代表chunk中最早接收的消息的时间戳
* end_time：8字节little-endian整数，代表chunk中最后接收的消息的时间戳
* count：4字节little-endian整数，代表chunk中建立的连接的数量

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

### 消息结构树的建立
　　