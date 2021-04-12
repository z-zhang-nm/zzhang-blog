---
title: "改变socket默认缓冲区大小"
date: 2021-04-08T10:26:34+08:00
categories:
- 计算机网络
- TCP/IP
tags:
- TCP/IP
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　TCP套接字有一个发送缓冲区和一个接收缓冲区，UDP套接字有一个接收缓冲区；使用SO_RCVBUF和SO_SNDBUF这两个套接字选项可以改变默认缓冲区大小。
<!--more-->
　　关于缓冲区的一些知识，参考[参考链接1](https://elsef.com/2020/02/29/%E4%B8%80%E4%B8%AATCP%E5%8F%91%E9%80%81%E7%BC%93%E5%86%B2%E5%8C%BA%E7%9A%84%E9%97%AE%E9%A2%98%E5%BC%95%E5%8F%91%E7%9A%84%E8%A7%A3%E6%9E%90/) 和 [参考链接2](http://nathanchen.github.io/14554141138605.html)
```cpp
// client.cpp
#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <iostream>

using namespace std;

#define MAXLINE 4096

int main(int argc, char **argv) {
  int sock_fd, n;
  char send_line[MAXLINE];
  struct sockaddr_in serv_addr;

  if (argc != 2) {
    cout << "usage: ./client <ip address>" << endl;
    return -1;
  }

  if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    cout << "create socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(6666);
  // inet_pton是IP地址转换函数，将IP地址在”点分十进制“和”二进制整数“之间转换
  // 若第一个参数指定的地址族与第二个参数格式不一致，函数返回0
  if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
    cout << "inet_pton error for " << argv[1] << endl;
    return -1;
  }

  if (connect(sock_fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    cout << "connect error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    return -1;
  }

  ssize_t write_len;
  char send_msg[246988] = {0};
  int count = 0;
  while (true) {
    if (++count == 5) {
      return 0;
    }
    write_len = write(sock_fd, send_msg, sizeof(send_msg));
    if (write_len < 0) {
      cout << "write failed!" << endl;
      close(sock_fd);
      return -1;
    }
    cout << "write sucess, write length: " << write_len << endl;
  }

  close(sock_fd);
  return 0;
}
```

```cpp
// server.cpp
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <iostream>

using namespace std;

#define MAXLINE 4096

int main(int argc, char **argv) {
  int listen_fd, conn_fd;
  struct sockaddr_in serv_addr;

  if ((listen_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
    cout << "create socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  // INADDR_ANY 多用于多网卡的机器，客户端可以连接到本机任一IP
  serv_addr.sin_addr.s_addr =
      htonl(INADDR_ANY);  // 小端序变大端序(network byte order) l: long 32-bits
  serv_addr.sin_port = htons(6666);  // s: short, 16-bits

  if (bind(listen_fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == -1) {
    cout << "bind socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  if (listen(listen_fd, 10) == -1) {
    cout << "listen socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  cout << "========Waiting for client's request========" << endl;
  if ((conn_fd = accept(listen_fd, (struct sockaddr *)NULL, NULL)) == -1) {
    cout << "accept socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  } else {
    cout << "accept sucess" << endl;
    int recv_buf_len;
    socklen_t len = sizeof(recv_buf_len);
    if (getsockopt(conn_fd, SOL_SOCKET, SO_RCVBUF,
                   static_cast<void *>(&recv_buf_len), &len) < 0) {
      perror("getsockopt: ");
      return -1;
    }
    cout << "the recv buffer length: " << recv_buf_len << endl;
  }
  char recv_msg[246988] = {0};
  ssize_t total_len = 0;
  while (true) {
    sleep(1);
    ssize_t read_len = read(conn_fd, recv_msg, sizeof(recv_msg));
    if (read_len < 0) {
      perror("read: ");
      return -1;
    } else if (read_len == 0) {
      cout << "read finish: length = " << total_len << endl;
      close(conn_fd);
      return 0;
    } else {
      cout << "read length: " << read_len << endl;
      total_len += read_len;
    }
  }
  close(conn_fd);
  close(listen_fd);
  return 0;
}
```
