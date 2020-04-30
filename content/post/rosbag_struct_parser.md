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
一个bag文件由record序列组成，文件第一行为格式标准版本信息。
```
#ROSBAG V2.0
<record 1><record 2>....<record N>
```
## Records
