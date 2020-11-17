---
title: "Cmake编译"
date: 2020-05-06T16:44:12+08:00
categories:
- C++
tags:
- C++基础
keywords:
- tech
---
CMake官网([CMake](https://cmake.org/overview/))介绍CMake是一个操作系统平台无关和编译器无关的用于管理编译（构建）过程的一个可扩展、开源系统，使用CMake可以简单的生成动态库，静态库和可执行文件。
<!--more-->
使用 CMake 生成 Makefile 并编译的流程如下：
1. 编写 CMake 配置文件 CMakeLists.txt
2. 执行命令 cmake PATH生成 Makefile，其中PATH 是 CMakeLists.txt 所在的目录
3. 使用 make 命令进行编译
# 单个源文件编译
