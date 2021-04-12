---
title: "简单TCP_server"
date: 2021-04-07T11:55:27+08:00
categories:
- 计算机网络
- TCP/IP
tags:
- TCP/IP
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　用TCP/IP协议编写一个简单服务器、客户端，服务器监听本机端口，若收到连接请求，将接收请求并接收客户端消息。
<!--more-->
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
  char buffer[MAXLINE];
  int n;

  if ((listen_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
    cout << "create socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return 0;
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
    return 0;
  }

  if (listen(listen_fd, 10) == -1) {
    cout << "listen socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return 0;
  }

  cout << "========Waiting for client's request========" << endl;
  while (true) {
    if ((conn_fd = accept(listen_fd, (struct sockaddr *)NULL, NULL)) == -1) {
      cout << "accept socket error: " << strerror(errno) << "(errno: " << errno
           << ")" << endl;
      continue;
    }
    // recv函数接收到的字符串是不带'\0'结束符的
    n = recv(conn_fd, buffer, MAXLINE, 0);
    buffer[n] = '\0';
    cout << "receive msg from client: " << buffer << endl;
    close(conn_fd);
  }
  close(listen_fd);
  return 0;
}
```

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
    return 0;
  }

  if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    cout << "create socket error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return 0;
  }

  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(6666);
  // inet_pton是IP地址转换函数，将IP地址在”点分十进制“和”二进制整数“之间转换
  // 若第一个参数指定的地址族与第二个参数格式不一致，函数返回0
  if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
    cout << "inet_pton error for " << argv[1] << endl;
    return 0;
  }

  if (connect(sock_fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    cout << "connect error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    return 0;
  }

  cout << "send msg to server: " << endl;
  fgets(send_line, MAXLINE, stdin);
  if (send(sock_fd, send_line, strlen(send_line), 0) < 0) {
    cout << "send msg error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    return 0;
  }
  close(sock_fd);
  return 0;
}
```
