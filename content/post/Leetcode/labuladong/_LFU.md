---
title: "LFU"
date: 2021-05-12T10:29:55+08:00
categories:
- Leetcode
- labuladong
tags:
- LFU
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
`LFU`的全称是`Least Frequently Used`，即最不经常使用淘汰算法
<!--more-->
[Leetcode.460](https://leetcode-cn.com/problems/lfu-cache/)题就是要实现一个「LFU缓存机制」的数据结构`LFUCache`类，与`LRUCache`类一样，提供两个接口，不过在`put`时若缓存达到其容量时，应该在**插入新项之前（保证新元素被插入，即使插入的新元素使用频次最低）**，使最不经常使用的项无效，且在两个或更多个键具有相同使用频次时，应该去除最近最久未使用的键（删除使用频次最低的键值对，若最低的键值对有多个，则删除其中最旧的那个）。

> 「项的使用次数」就是自插入该项以来对其调用`get`和`put`函数的次数之和，使用次数会在对应项被移除后置为0，为了确定最不常使用的键，可以为缓存中的每个键维护一个**使用计数器**，使用计数最小的键是最久未使用的键

工作过程举例：
```cpp
// 构造一个容量为 2 的 LFU 缓存
LFUCache *cache = new LFUCache(2);

// 插入两对 (key, val)，对应的 freq 为 1
cache->put(1, 1);
cache->put(2, 2);

// 查询 key 为 1 对应的 val
// 返回 10，同时键 1 对应的 freq 变为 2
cache->get(1);

// 容量已满，淘汰 freq 最小的键 2
// 插入键值对 (3, 3)，对应的 freq 为 1
cache->put(3, 3);

// 键 2 已经被淘汰删除，返回 -1
cache->get(2);
```

# 数据结构设计
1. `LRU`只需将元素按照时间顺序存入list，链表底部的位置总是最近未被使用的元素，每次删除底部的元素即可，而`LFU`需要删除使用次数最少的元素，因此需要统计每一个元素被使用的次数，即用**一个哈希表key_freq记录元素键值和其被使用次数之间的映射**
2. 由于当删除使用频次最低的元素时元素可能有多个，此时问题就变为`LRU`，即在这些使用频次相同的元素中删除最久未使用的元素，可以想到为每个使用频次建立一个链表，这个链表代表这个使用频次的元素的`LRU`，即用**另一个哈希表freq_list建立使用频次和元素list之间的映射**
3. 为了快速定位元素位置，需要用**另一个哈希表key_iter建立元素键值和各个元素list中元素位置之间的映射**

![数据结构图]()

为了更好的实现算法，先用一个例子进行说明，假设`cache`容量为2，已经按顺序`put`了`(5,5), (4,4)`两个元素，此时`LFUCache`中各成员如下：
```cpp
key_freq: {4 : 1, 5 : 1}
freq_list: {1 : (4,4)->(5,5)}
key_iter: {4: list1.begin(), 5 : list1.begin()+1}
min_freq = 1
```

下一步执行`get(5)`，需要做如下操作：
1. 在key_freq中查找是否存在5，获取其对应的value（若未查找到，返回-1）
2. 从freq_list中频次为1的list中将5删除
3. 将key_freq中5对应的频次加1
4. 将5加入freq_list中频次为2的list的头部
5. 将key_iter中5对应的iter改为5在freq_list中频次为2的list中的位置
6. 如果freq_list中频次为min_freq的list为空，min_freq加1
7. 返回5对应的value值

经过这些步骤后，`LFUCache`各成员如下：
```cpp
key_freq: {4 : 1, 5 : 2}
freq_list: {1 : (4,4), 2 : (5,5)}
key_iter: {4: list1.begin(), 5 : list2.begin()}
min_freq = 1
```

下一步执行`put(7)`，需要做如下操作：
1. 调用`get(7)`，返回-1（若不是-1，即不是新增元素，由于get已经执行了更新操作，只需再更新7对应的value值即可返回）
2. 若key_freq的大小等于容量，则获取freq_list中频率为min_freq的list的尾部元素并清除key_freq和key_iter中对应的记录，然后移除这个尾部元素
1. 在key_freq中建立7的映射
2. 在freq_list中频率为1的list头部加上7
3. 在key_iter中保存7在freq_list中频次为1的list中的位置
4. 将min_freq赋值为1

经过这些步骤后，`LFUCache`各成员如下：
```cpp
key_freq: {5 : 2, 7 : 1}
freq_list: {1 : (7,7), 2 : (5,5)}
key_iter: {5 : list2.begin(), 7 : list1.begin()}
min_freq = 1
```

算法实现：
```cpp
class LFUCache {
public:
    LFUCache(int capacity) : cap(capacity), min_freq(0) {}

    int get(int key) {
        if (key_freq.count(key) == 0) return -1;
        int val = key_iter[key]->second;
        freq_list[key_freq[key]].erase(key_iter[key]);
        key_freq[key] += 1;
        freq_list[key_freq[key]].push_front(make_pair(key, val));
        key_iter[key] = freq_list[key_freq[key]].begin();
        if (freq_list[min_freq].empty()) min_freq += 1;
        return key_iter[key]->second;
    }

    void put(int key, int value) {
        if (cap <= 0) return;
        if (get(key) != -1) {
            key_iter[key]->second = value;
            return;
        }
        if (key_freq.size() == cap) {
            int key = freq_list[min_freq].rbegin()->first;
            key_freq.erase(key);
            key_iter.erase(key);
            freq_list[min_freq].pop_back();
        }
        key_freq[key] = 1;
        freq_list[1].push_front(make_pair(key, value));
        key_iter[key] = freq_list[1].begin();
        min_freq = 1;
    }

private:
    int cap, min_freq;
    unordered_map<int, int> key_freq;
    unordered_map<int, list<pair<int, int>>> freq_list;
    unordered_map<int, list<pair<int, int>>::iterator> key_iter;
};
```
