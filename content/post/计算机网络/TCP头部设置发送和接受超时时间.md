---
title: "TCP头部设置发送和接受超时时间"
date: 2021-04-07T18:14:41+08:00
categories:
- 计算机网络
- TCP/IP
tags:
- TCP/IP
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　设置socket的发送和接收超时时间。
<!--more-->
　　TCP头部选项SO_SNDTIMEO和SO_RCVTIMEO分别设置了socket发送和接收超时时间，它们都接收一个timeval结构作为参数，当timeval结构为0时，表示选项无效。

　　接收超时会影响read、readv、recv、recvfrom和recvmsg的状态；发送超时会影响write、writev、send、sendto和sendmsg的状态。

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

  struct timeval stTimeVal;
  stTimeVal.tv_sec = 2;
  stTimeVal.tv_usec = 0;
  // 设置发送超时时间为2秒
  if (setsockopt(sock_fd, SOL_SOCKET, SO_SNDTIMEO, &stTimeVal,
                 sizeof(stTimeVal))) {
    cout << "setsockopt error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  // 设置接收超时时间为2秒
  if (setsockopt(sock_fd, SOL_SOCKET, SO_RCVTIMEO, &stTimeVal,
                 sizeof(stTimeVal))) {
    cout << "setsockopt error: " << strerror(errno) << "(errno: " << errno
         << ")" << endl;
    return -1;
  }

  ssize_t write_len;
  char send_msg[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '\0'};
  int count = 0;
  write_len = write(sock_fd, send_msg, sizeof(send_msg));
  if (write_len < 0) {
    cout << "write error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    close(sock_fd);
    return -1;
  } else {
    cout << "write success, write length: " << write_len
         << ", send_msg: " << send_msg << endl;
  }
  char read_msg[10] = {0};
  int read_len = read(sock_fd, read_msg, sizeof(read_msg));
  if (read_len < 0) {
    cout << "read error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    close(sock_fd);
    return -1;
  } else {
    read_msg[9] = '\0';
    cout << "read sucess, read length: " << read_len
         << ", read msg: " << read_msg << endl;
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
  char buffer[MAXLINE];
  int n;

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
  }
  char recv_msg[10];
  ssize_t read_len = read(conn_fd, recv_msg, sizeof(recv_msg));
  if (read_len < 0) {
    cout << "read error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    close(conn_fd);
    return -1;
  }
  recv_msg[9] = '\0';
  cout << "read length: " << read_len << ", recv_msg: " << recv_msg << endl;
  sleep(5);
  recv_msg[1] = '9';
  ssize_t write_len = write(conn_fd, recv_msg, sizeof(recv_msg));
  if (write_len < 0) {
    cout << "write error: " << strerror(errno) << "(errno: " << errno << ")"
         << endl;
    close(conn_fd);
    return -1;
  }
  cout << "write length: " << write_len << ", send_msg: " << recv_msg << endl;

  close(listen_fd);
  return 0;
}
```

　　客户端给服务端发送一个请求，服务端接收后休眠5秒，之后给客户端回包，但是此时客户端已经关闭，因为客户端设置了接收超时时间为2秒。若服务端休眠时间少于接收超时，即2秒，则可以成功回包。
