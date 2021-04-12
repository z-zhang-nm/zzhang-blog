---
title: "Spin和spinOnce"
date: 2021-04-07T15:05:14+08:00
categories:
- ros
tags:
- spin
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　ros::spin()和ros::spinOnce()之间有什么区别呢？
<!--more-->
　　这两个函数都是消息回调处理函数，通常出现在ROS主循环中，程序需要不断调用这两个函数，两者主要区别在于前者调用后不会再返回，也就是主程序运行到这里就不往下执行了，而后者在调用后还可以继续执行后面的程序。

　　若程序写了消息订阅函数，那么在程序执行过程中，除了主程序外，ROS还会在后台接收订阅的消息，但所接收到的消息不是立刻被处理，而是必须等到ros::spin或ros::spinOnce执行的时候才被调用。

## ros::spin()
　　一般放在主程序最后，如下例子：
```cpp
// 发送端
#include "ros/ros.h"
#include "std_msgs/String.h"
#include <sstream>

int main(int argc, char **argv)
{
  ros::init(argc, argv, "talker");
  ros::NodeHandle n;
  ros::Publisher chatter_pub = n.advertise<std_msgs::String>("chatter", 1000);
  ros::Rate loop_rate(10);

  int count = 0;
  while (ros::ok())
  {
      std_msgs::String msg;
      std::stringstream ss;
      ss << "hello world " << count;
      msg.data = ss.str();
      ROS_INFO("%s", msg.data.c_str());

      /**
       * 向 Topic: chatter 发送消息, 发送频率为10Hz（1秒发10次）；消息池最大容量1000。
       */
      chatter_pub.publish(msg);

      loop_rate.sleep();
      ++count;
  }
  return 0;
}
```

```cpp
// 接收端
#include "ros/ros.h"
#include "std_msgs/String.h"

void chatterCallback(const std_msgs::String::ConstPtr& msg)
{
    ROS_INFO("I heard: [%s]", msg->data.c_str());
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "listener");
  ros::NodeHandle n;
  ros::Subscriber sub = n.subscribe("chatter", 1000, chatterCallback);

  /**
   * ros::spin() 将会进入循环， 一直调用回调函数chatterCallback(),每次调用1000个数据。
   * 当用户输入Ctrl+C或者ROS主进程关闭时退出，
   */
  ros::spin();
    return 0;
}
```

## ros::spinOnce()
　　使用起来比ros::spin灵活，可以出现在程序各个部位。

　　对于传输速率比较快的消息来说，需要合理控制线程池大小和ros::spinOnce执行频率，比如消息传输频率为10HZ，ros::spinOnce调用频率为5HZ，那么消息池大小一定要大于2，才能保证数据不丢失，无延迟。

```cpp
#include "ros/ros.h"
#include "std_msgs/String.h"

void chatterCallback(const std_msgs::String::ConstPtr& msg)
{
  /*...TODO...*/ 
}

int main(int argc, char **argv)
{
  ros::init(argc, argv, "listener");
  ros::NodeHandle n;
  ros::Subscriber sub = n.subscribe("chatter", 2, chatterCallback);

  ros::Rate loop_rate(5);
  while (ros::ok())
  {
      /*...TODO...*/

      ros::spinOnce();
      loop_rate.sleep();
  }
  return 0;
}
```

　　对用户自定义的周期性函数，最好和ros::spinOnce并列执行，不建议放在回调函数中。

```cpp
/*...TODO...*/
ros::Rate loop_rate(100);

while (ros::ok())
{
  /*...TODO...*/
  user_handle_events_timeout(...);

  ros::spinOnce();
  loop_rate.sleep();
}
```

　　[参考链接](https://www.cnblogs.com/liu-fa/p/5925381.html)
