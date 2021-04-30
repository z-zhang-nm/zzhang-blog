---
title: "Git原理之最近公共祖先"
date: 2021-04-30T09:35:43+08:00
categories:
- Leetcode
- labuladong
tags:
- 最近公共祖先
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
rebase合并代码
<!--more-->
如下图示，在`dev`分支上进行`git rebase master`就会把`dev`接到`master`之上：
![rebase]()

Git会做如下操作：
1. 找到最近公共祖先`LCA`
2. 从`master`节点开始，重演`LCA`到`dev`的各个提交
3. 若与`LCA`到`master`的提交有冲突，会提示手动解决冲突
4. 最终会将`dev`分支完全接到`master`上

那么如何找到[最近的公共祖先](https://leetcode-cn.com/problems/lowest-common-ancestor-of-a-binary-tree/)呢？

> 最近公共祖先的定义为：对于有根树`T`的两个节点`p、q`，最近公共祖先表示为一个节点`x`，满足`x`是`p、q`的祖先且`x`的深度尽可能大（一个节点也可以是它自己的祖先）

若`root`是`p, q`的最近公共祖先，只可能有三种情况：
1. `p`和`q`分别在`root`左右子树中
2. `root == p`， `q`在`root`左子树或右子树
3. `root == q`， `p`在`root`左子树或右子树

看到二叉树的问题，先写出如下递归框架：
```cpp
TreeNode *lowestCommonAncestor(TreeNode *root, TreeNode *p, TreeNode *q) {
  TreeNode *left = lowestCommonAncestor(root->left, p, q);
  TreeNode *right = lowestCommonAncestor(root->right, p, q);
}
```

递归问题需要思考：
1. 递归函数的定义及返回结果
2. 怎么利用递归函数的结果

# 递归函数的定义
函数输入三个参数`root, p ,q`，返回一个节点，这个节点为`root`中`p, q`的最近公共祖先，有如下三种情况：
1. `p, q`都在以`root`为根的树中，那么返回的就是它们的最近公共祖先
2. `p, q`都不在以`root`为根的树中，返回`nullptr`，`base case`为到达叶子节点返回`nullptr`
3. `p, q`只有一个在`root`为根的树中，这种情况根据递归函数定义理应返回`nullptr`，但是这种情况只会出现在递归调用的过程中（题目规定`p, q`一定在`root`中），递归调用左右子树时有两种情况：
   1. `p, q`分别在左右子树中，那么左右子树的递归即为讨论的第三种情况，此时第三种情况的返回结果应该是`root`，那么若左右子树都返回`nullptr`，最终结果也是`nullptr`，那么就让左右子树返回其自己吧（返回一个非空好判断），`base case`到达`p`或`q`，返回自己
   2. `p, q`在一侧，那么左子树返回非空，右子树返回空或左子树返回空，右子树返回非空，此时结果为非空的那个

```cpp
TreeNode* lowestCommonAncestor(TreeNode* root, TreeNode* p, TreeNode* q) {
    if (!root || p == root || q == root) return root;
    TreeNode *left = lowestCommonAncestor(root->left, p, q);
    TreeNode *right = lowestCommonAncestor(root->right, p , q);
    if (left && right) return root;
    return left ? left : right;
}
```
