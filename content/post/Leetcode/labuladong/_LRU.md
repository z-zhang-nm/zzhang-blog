---
title: "LRU"
date: 2021-05-08T16:12:01+08:00
categories:
- Leetcode
- labuladong
tags:
- LRU
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
`LRU`的全称是`Least Recently Used`，即最近最少使用淘汰算法
<!--more-->
[Leetcode.146](https://leetcode-cn.com/problems/lru-cache/)题就是要实现一个「LRU缓存机制」的数据结构`LRUCache`类，构造函数接收一个正整数作为容量；类提供两个接口，一个是`void put(key, val)`，如果关键字已经存在，则变更其数据值；如果关键字不存在，则插入该组「关键字-值」。当缓存容量达到上限时，它应该在写入新数据之前删除最久未使用的数据值，从而为新的数据值留出空间；另一个是`int get(int key)`，如果关键字`key`存在于缓存中，则返回关键字的值，否则返回 -1。

题目要求`get`和`put`方法都是`O(1)`时间复杂度，下面举例说明LRU算法怎么工作：
```cpp
/* 缓存容量为 2 */
LRUCache *cache = new LRUCache(2);
// 可以把 cache 理解成一个队列
// 假设左边是队头，右边是队尾
// 最近使用的排在队头，久未使用的排在队尾
// 圆括号表示键值对 (key, val)

cache->put(1, 1);
// cache = [(1, 1)]

cache->put(2, 2);
// cache = [(2, 2), (1, 1)]

int val1 = cache->get(1);       // 返回 1
// cache = [(1, 1), (2, 2)]
// 解释：因为最近访问了键 1，所以提前至队头
// 返回键 1 对应的值 1

cache->put(3, 3);
// cache = [(3, 3), (1, 1)]
// 解释：缓存容量已满，需要删除内容空出位置
// 优先删除久未使用的数据，也就是队尾的数据
// 然后把新的数据插入队头

int val2 = cache->get(2);       // 返回 -1 (未找到)
// cache = [(3, 3), (1, 1)]
// 解释：cache 中不存在键为 2 的数据

cache->put(1, 4);
// cache = [(1, 4), (3, 3)]
// 解释：键 1 已存在，把原始值 1 覆盖为 4
// 不要忘了也要将键值对提前到队头
```

# 数据结构设计
1. `cache`需要有**时序**以区分最近使用和久未使用的数据
2. `cache`需要`get`后需要将其提至最近使用，即需要满足在**任意位置快速删除元素**
3. `cache`需要**快速查找**某个元素是否存在并返回其`val`

首先**快速查找**这一要求容易想到**哈希表**，但是其元素不满足固定顺序，其次**任意位置快速删除元素**这一要求容易想到**链表**，且链表是有**时序**的，因此需要将链表和哈希表相结合形成一种新的数据结构：**哈希链表**。

下面讨论这个数据结构的具体实现细节，时刻记得每次操作都要考虑**链表**和**哈希表**两个内部数据结构：
1. `put`接口的实现
   1. 插入前需要判断哈希表中是否已有当前元素，若存在需要先删除后加入
   2. 每次从链表头部插入元素，越靠近头部的元素就是最近使用的
   3. 若超出`cache`容量限制，需要删除链表尾部元素和哈希表对应元素
2. `get`接口的实现
   1. 在哈希表中查找元素是否存在，若不存在，返回-1，若存在将链表对应元素提至链表头部
   2. 由于任何位置的元素都可能被提到头部，需要常数时间操作链表中间的元素，因此使用双向链表
3. 怎么建立哈希表元素和链表元素之间的关系？
   1. 链表存储键值对`key-val`作为其节点
   2. 哈希表协助链表元素的定位，因此对应键值`key`存储链表元素的迭代器作为其`val`

![数据结构图]()

```cpp
class LRUCache {
public:
  LRUCache(int capacity) : cap(capacity) {}
  int get(int key) {
    auto it = m.find(key);
    if (it == m.end()) return -1;
    // void splice ( iterator pos, list& l, iterator it );
    // 将 list l 中的由迭代器 it 指向的元素移到 caller container 的 position 处
    l.splice(l.begin(), l, it->second);
    return it->second->second;
  }
  void put(int key, int value) {
    auto it = m.find(key);
    if (it != m.end()) l.erase(it->second);
    l.push_front(make_pair(key, value));
    m[key] = l.begin();
    if (m.size() > cap) {
      int k = l.rbegin()->first;
      l.pop_back();
      m.erase(k);
    }
  }
private:
  int cap;
  list<pair<int, int>> l;
  unordered_map<int, list<pair<int, int>>::iterator> m;
};
```
