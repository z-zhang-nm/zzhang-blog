---
title: "Union Find"
date: 2021-05-07T09:51:24+08:00
categories:
- Leetcode
- labuladong
tags:
- 并查集
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
图论「动态连通性」问题
<!--more-->
# 1. 动态连通性介绍
动态连通性可以抽象为给一幅图连线，Union-Find算法包含如下功能：
```cpp
class UF {
  // 将节点 p 和 q 连接
  void merge(int p, int q);
  // 判断节点 p 和 q 是否连通
  bool connected(int p, int q);
  // 节点 p 的代表元
  bool find(int p);
  // 图中有几个连通分量
  int getCount();
};
```

**连通**具有如下三个性质：
1. 自反性：节点`p`和`p`是连通的
2. 对称性：如果节点`p`和`q`连通，那么`q`和`p`也连通
3. 传递性：如果节点`p`和`q`连通，`q`和`r`连通，那么`p`和`r`也连通

# 2. 算法思想
并查集顾名思义就是有*合并集合*和*查找集合中的元素*两种操作的关于数据结构的一种算法，用集合中的某个元素来代表这个集合，该元素称为集合的**代表元**，对于只有一个元素的集合，代表元素自然是唯一的那个元素。

- 合并集合：把两个不相交的集合合并为一个集合
- 查询：查询两个元素是否在同一个集合中

> 用公司的组织架构关系来比喻并查集，公司刚成立时只有几个创始人（初始节点），他们各自管理各自的工作（各自的代表元是自己），随着公司不断扩大，每个创始人成立了自己的团队（集合，代表元为创始人），各个团队下面有不同的部门，每个部门又有一个领导人，管理各自的员工（每一个员工的代表元为各团队创始人，直属领导为部门领导人）；若要判断两个员工是否属于同一个团队（查询），只需要看他们的代表元是否是同一个人即可；要合并两个团队的话（合并集合），只需要在原来的两个领导人中选出一个作为新团队的领导人（代表元），另一个领导人的团队变为新团队的一个部门即可。

可以看出这是一个树形结构，要寻找代表元，只需要一层一层向上访问直到根结点即可，至此，可以实现最简单的并查集：
```cpp
// 初始化
class UF {
 public:
  explicit UF(int n) : count(n), parent(vector<int>(n, 0)) {
    for (int i = 0; i < n; ++i) {
      parent[i] = i;
    }
  }
  int find(int p);
  void merge(int p, int q);
  bool connected(int p, int q);
  int getCount();

 private:
  int count;
  vector<int> parent;
};
// 查询
int UF::find(int p) {
  while (parent[p] != p) {
    p = parent[p];
  }
  return p;
}
// 合并，前者合并到后者
void UF::merge(int p, int q) {
  if (connected(p, q)) return;
  parent[find(p)] = find(q);
  count -= 1;
}
bool UF::connected(int p, int q) {
  reeturn find(p) == find(q);
}
int UF::getCount() { return count; }
```

可以看出主要接口`merge`和`connected`的复杂度都是`find`函数造成的，而`find`函数的复杂度和树的高度有关，因此要进行平衡性优化和路径压缩。

# 3. 平衡性优化
可能破坏平衡性的操作只有合并的时候，看下图的这种情况：
![合并]()

我们希望小一些的树接到大一些的树下面，因此使用一个`size`数组记录每棵树包含的高度：
```cpp
class UF {
 public:
  explicit UF(int n) : count(n), parent(vector<int>(n, 0)), size(vector<int>(n, 1)) {
    for (int i = 0; i < n; ++i) {
      parent[i] = i;
    }
  }
  ...

 private:
  int count;
  vector<int> parent;
  vector<int> size;
};
```

修改`merge`方法：
```cpp
void UF::merge(int p, int q) {
  int root_p = find(p), root_q = find(q);
  if (root_p == root_q) return;
  if (size[root_p] >= size[root_q]) {
    parent[root_q] = root_p;
  } else {
    parent[root_p] = root_q;
  }
  // 深度相同且根节点不同，则新的根节点的深度+1
  if (size[root_p] == size[root_q]) {
    size[root_p] += 1;
  }
  count -= 1;
}
```

树的高度大致在logN这个数量级，极大提升效率。

# 4. 路径压缩
进一步压缩每棵树的高度，由于我们只关心一个元素对应的根节点，那我们希望每个元素到根节点的路径尽可能短，最好只需要一步，这样复杂度就为常数级别，只需要
**在查询的过程中，把沿途的每个节点的父节点都设为根节点即可**。
```cpp
int UF::find(int p) {
  return (p == parent[p]) ? x : (parent[p] = find(parent[p]));
}
```

将上面代码展开比较好理解：
```cpp
int UF::find(int p) {
  if(p == parent[p])
      return p;
  else{
      parent[p] = find(parent[p]);  //父节点设为根节点
      return parent[p];         //返回父节点
  }
}
```
