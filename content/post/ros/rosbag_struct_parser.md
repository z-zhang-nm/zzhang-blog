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
　　首先参照官方文档介绍rosbag的数据存储结构，一个bag文件由record序列组成，文件第一行为格式标准版本信息。
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
## Header format
　　每一个header由name=value fields序列组成，如下：
```
<field1_len><field1_name>=<field1_value><field2_len><field2_name>=<field2_value>...<fieldN_len><fieldN_name>=<fieldN_value>
```
* fieldX_len为４字节little-endian整数，代表其后fieldX_name和fieldX_value的长度（包括符号'='）
* fieldX_name为字符串，代表field的名字
* fieldX_value格式由field具体指定，代表field的具体值

　　每一个header都包含一个名字为op的field，用来指定record的类别，包括以下几种类别（按在bag包中首次出现的顺序列出）：
1. Bag header(op=0x03)：存储整个bag包的结构信息，例如第一个index data record的偏置，chunk records和connection records的数量等
2. Chunk(op=0x05)：存储connection records（可能是被压缩的）和message records
3. Connection(op=0x07)：存储[ROS connection header](#ros-connection-header)，包括topic名字和消息定义文本
4. Message data(op=0x02)：存储序列化的消息数据（长度可为0）和connection的ID
5. Index data(op=0x04)：存储前面chunk record单个connection中消息的索引
6. Chunk info(op=0x06)：存储chunk中消息的信息
### ROS connection header
　　存储建立的连接的元数据，field_name和field_value都是字符串，格式：
```
4-byte length + [4-byte field length + field_name=field_value]*
```
　　TCPROS是供ROS消息和服务端使用的一个传输层，使用标准TCP/IP套接字来传输消息，TCPROS connections包括如下fields：
* TCPROS subscriber 需要发送如下fields:
  * message_definition：消息定义的文本
  * callerid：subscriber的名字
  * topic：订阅的topic名字
  * md5sum：消息类型的md5sum
  * type：消息类型
  * latching：发布消息的模式（发送最新消息给订阅者）
* TCPROS publisher连接成功时返回如下fields：
  * md5sum： 消息类型的md5sum
  * type：消息类型
## Records
### Bag header
　　rosbag的第一个record，具有固定的4096字节的长度，不足4096字节的部分用ASCII空白符(0x20)填充，header包含如下fields：
* index_pos：8字节little-endian整数，代表chunk后第一个record的偏置
* conn_count：4字节little-endian整数，代表connections的数量
* chunk_count： 4字节little-endian整数，代表chunk records的数量
### Chunk
　　data存储压缩后的Message data Records和Connection Records，header包含如下fields：
* compression：字符串类型，代表数据压缩方法
* size：4字节little-endian整数，代表未压缩的消息块的大小
### Connection
　　data存储[connection header](#ros-connection-header)字符串，connection header一定包含**topic, type, md5sum, message_defination**这几个fields，可以包含**callerid, latching** fields，header包含如下fields：
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
* count：4字节little-endian整数，代表conn这个链接中的消息数量
### Chunk info
　　data格式取决于header中存储的版本号，当前版本为1，data包含连接ID（4字节little-endian整数）、连接中的消息数量（4字节little-endian整数），header包含如下fields：
* ver： 4字节little-endian整数，代表chunk info record的版本
* chunk_pos：8字节little-endian整数，代表chunk record的偏置
* start_time：8字节little-endian整数，代表chunk中最早接收的消息的时间戳
* end_time：8字节little-endian整数，代表chunk中最后接收的消息的时间戳
* count：4字节little-endian整数，代表chunk中建立的连接的数量

# Rosbag数据结构解析