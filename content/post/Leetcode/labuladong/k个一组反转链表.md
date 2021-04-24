---
title: "K个一组反转链表"
date: 2021-04-21T10:09:20+08:00
categories:
- Leetcode
- labuladong
tags:
- 链表
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
　　迭代方法
<!--more-->
> 给定一个链表，每K个节点一组进行反转，K是一个正整数且值小于等于链表长度，若链表长度不是K的整数倍，最后剩余的节点保持原有顺序

# 1. 递归方法实现
```cpp
class Solution {
    ListNode *successor = nullptr;
public:
    ListNode* reverseKGroup(ListNode* head, int k) {
        int n = 0;
        for (ListNode *cur = head; cur != nullptr; cur = cur->next) {
            n += 1;
        }
        return reverseKGroup(head, k, n);
    }

    ListNode *reverseKGroup(ListNode *head, int k, int n) {
        if (n < k) {
            return head;
        }
        ListNode *preccesor = head;
        head = reverseN(head, k);
        ListNode *last = reverseKGroup(preccesor->next, k, n-k);
        preccesor->next = last;
        return head;
    }

    ListNode *reverseN(ListNode *head, int n) {
        if (n == 1) {
            successor = head->next;
            return head;
        }
        ListNode *last = reverseN(head->next, n-1);
        head->next->next = head;
        head->next = successor;
        return last;
    }
};
```

# 2. 迭代方法
## 2.1 反转整个链表
```cpp
ListNode *reverse(ListNode *head) {
  if (head == nullptr) return head;
  ListNode *pre = nullptr, *cur = head, *nxt = head;
  while (cur != nullptr) {
    nxt = cur->next;
    cur->next = pre;
    pre = cur;
    cur = nxt;
  }
  return pre;
}
```

## 2.2 反转链表前N个节点
```cpp
ListNode *reverseN(ListNode *head, int n) {
  if (n == 1) return head;
  ListNode *successor = head;
  for (int i = 0; i < n; ++i) {
    successor = successor->next;
  }
  ListNode *pre = successor, *cur = head, nxt = head;
  while (cur != successor) {
    nxt = cur->next;
    cur->next=pre;
    pre = cur;
    cur = nxt;
  }
  return pre;
}
```

## 2.3 反转链表的一部分
```cpp
ListNode* reverseBetween(ListNode* head, int left, int right) {
    ListNode *dummy = new ListNode(-1);
    dummy->next = head;
    ListNode *pre_left = dummy, *suc_right = head;
    for (int i = 0; i < left-1; ++i) {
        pre_left = pre_left->next;
    }
    for (int i = 0; i < right; ++i) {
        suc_right = suc_right->next;
    }
    ListNode *pre = suc_right, *cur = pre_left->next, *nxt = pre_left->next;
    while (cur != suc_right) {
        nxt = cur->next;
        cur->next = pre;
        pre = cur;
        cur = nxt;
    }
    pre_left->next = pre;
    return dummy->next;
}
```

## 2.4 用迭代方法实现k个一组反转链表
```cpp
ListNode* reverseKGroup(ListNode* head, int k) {
    if (k == 1) return head;
    ListNode *successor = head;
    for (int i = 0; i < k; ++i) {
        if(successor == nullptr) return head;
        successor = successor->next;
    }
    ListNode *new_head = reverseN(head, successor, k);
    head->next = reverseKGroup(successor, k);
    return new_head;
}
ListNode *reverseN(ListNode *head, ListNode *successor,int n) {
    ListNode *pre = successor, *cur = head, *nxt = cur;
    while (cur != successor) {
        nxt = cur->next;
        cur->next = pre;
        pre = cur;
        cur = nxt;
    }
    return pre;
}
```

- [k个一组反转链表](https://labuladong.gitee.io/algo/%E9%AB%98%E9%A2%91%E9%9D%A2%E8%AF%95%E7%B3%BB%E5%88%97/k%E4%B8%AA%E4%B8%80%E7%BB%84%E5%8F%8D%E8%BD%AC%E9%93%BE%E8%A1%A8.html)
- [leetcode](https://leetcode-cn.com/problems/reverse-nodes-in-k-group/)

