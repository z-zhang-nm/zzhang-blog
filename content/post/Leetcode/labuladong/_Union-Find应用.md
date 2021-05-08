---
title: "Union Find应用"
date: 2021-05-08T09:46:18+08:00
categories:
- Leetcode
- labuladong
tags:
- 并查集
keywords:
- tech
#thumbnailImage: //example.com/image.jpg
---
并查集算法解决的是图的动态连通性问题，需要将原始问题抽象成一个有关图论的问题
<!--more-->
# 1. 被围绕的区域
## 1.1 DFS
> 很多使用`DFS`深度优先算法解决的问题，也可以用`Union-Find`算法解决。

从题目可以得知四条边上的`O`是不可能被替换的，且与四条边上的`O`相连的`O`也不会被替换，其余的`O`肯定被`X`包围，一种思路是`DFS`遍历中间的`O`，如果没有到达边缘，都变成`X`，如果到达了边缘，将之前变成`X`的再变回来，但是这样实现起来很麻烦，可以扫矩阵的四条边，如果有`O`，则用`DFS`遍历，将所有连着的`O`都变成另一个字符，比如`#`，这样剩下的`O`都是被包围的，然后将这些`O`变成`X`，把`$`变回`O`就行了。

```cpp
class Solution {
    vector<vector<int>> dir{{0,-1},{-1,0},{0,1},{1,0}};
public:
    void solve(vector<vector<char>>& board) {
        if(board.empty() || board[0].empty()) return;
        int m = board.size(), n = board[0].size();
        for (int i = 0; i < m; ++i) {
            for (int j = 0; j < n; ++j) {
                if (i == 0 || i == m-1 || j == 0 || j == n-1) {
                    if (board[i][j] == 'O') {
                        dfs(board, i, j);
                    }
                }
            }
        }
        for (int i = 0; i < m; ++i) {
            for (int j = 0; j < n; ++j) {
                if (board[i][j] == 'O') {
                    board[i][j] = 'X';
                }
                if (board[i][j] == '#') {
                    board[i][j] = 'O';
                }
            }
        }
    }
    void dfs(vector<vector<char>> &board, int i, int j) {
        int m = board.size(), n = board[0].size();
        board[i][j] = '#';
        for (int k = 0; k < dir.size(); ++k) {
            int next_i = i + dir[k][0];
            int next_j = j + dir[k][1];
            if (next_i >= 0 && next_i < m && next_j >= 0 && next_j < n) {
                if (board[next_i][next_j] == 'O') {
                    dfs(board, next_i, next_j);
                }
            }
        }
    }
};
```

## 1.2 DFS的替代方案
> `Union-Find`算法解决问题的思路一般是**适时增加虚拟节点，想办法让元素“分门别类”，建立动态连通关系**。

把不需要被替换的`O`连通为一个集合，让它们都指向一个虚拟节点`dummy`，而那些不需要被替换的`O`和`dummy`不连通，如下图：
![dummy]()

题目给定了一个二维数组，而`Union-Find`算法的底层使用的是一维数组，因此需要进行二维坐标`(x, y)`到一维坐标的转换：`x * n + y`，初始化一个大小为`m * n + 1`的一维数组，用`m * n`位置的节点代表`dummy`节点。

```cpp
class UF {
public:
    explicit UF(int n) : parent(vector<int>(n, 0)), height(vector<int>(n, 1)) {
        for (int i = 0; i < n; ++i) parent[i] = i;
    }
    int find(int x) {
        return (x == parent[x]) ? x : (parent[x] = find(parent[x])); 
    }
    bool connected(int p, int q) {
        return find(p) == find(q);
    }
    void merge(int p, int q);
private:
    vector<int> parent;
    vector<int> height;
};

void UF::merge(int p, int q) {
    int root_p = find(p), root_q = find(q);
    if (root_p == root_q) return;
    if (height[root_p] >= height[root_q]) {
        parent[root_q] = root_p;
    } else {
        parent[root_p] = root_q;
    }
    if (height[root_p] == height[root_q]) {
        height[root_p] += 1;
    }
}

class Solution {
    vector<vector<int>> dir{{0,-1},{-1,0},{0,1},{1,0}};
public:
    void solve(vector<vector<char>>& board) {
        if(board.empty() || board[0].empty()) return;
        int m = board.size(), n = board[0].size();
        UF uf = UF(m * n + 1);
        int dummy = m * n;
        // 将首列和末列的 O 与 dummy 连通
        for (int i = 0; i < m; ++i) {
            if (board[i][0] == 'O') uf.merge(i * n, dummy);
            if (board[i][n-1] == 'O') uf.merge(i * n + n-1, dummy);
        }
        // 将首行和末行的 O 与 dummy 连通
        for (int j = 0; j < n; ++j) {
            if (board[0][j] == 'O') uf.merge(j, dummy);
            if (board[m-1][j] == 'O') uf.merge((m-1) * n + j, dummy);
        }
        // 将中间区域的 O 连通
        for (int i = 1; i < m-1; ++i) {
            for (int j = 1; j < n-1; ++j) {
                if (board[i][j] == 'O') {
                    for (int k = 0; k < dir.size(); ++k) {
                        int next_i = i + dir[k][0];
                        int next_j = j + dir[k][1];
                        if (board[next_i][next_j] == 'O') {
                            uf.merge(i * n + j, next_i * n + next_j);
                        }
                    }
                }
            }
        }
        // 替换所有不和 dummy 连通的 O
        for (int i = 1; i < m-1; ++i) {
            for (int j = 1; j < n-1; ++j) {
                if (!uf.connected(dummy, i * n + j)) {
                    board[i][j] = 'X';
                }
            }
        }
    }
};
```

# 2. 判定合法等式
> [等式方程的可满足性](https://leetcode-cn.com/problems/satisfiability-of-equality-equations/)

由题目得知每个字符串方程的长度固定，都为4，且只有相等和不等两种形式，题目给定一组方程，要判断这些方程是否互不冲突，即是否可以同时成立。

将满足相等关系的变量组成一个集合，然后逐个判断满足不等关系的变量是否同属于满足相等关系集合即可。

```cpp
class UF {
public:
    explicit UF(int n) : parent(vector<int>(n, 0)), height(vector<int>(n, 1)) {
        for (int i = 0; i < n; ++i) parent[i] = i;
    }
    int find(int x) {
        return (x == parent[x]) ? x : (parent[x] = find(parent[x]));
    }
    bool connected(int p, int q) {
        return find(p) == find(q);
    }
    void merge(int p, int q);
private:
    vector<int> parent;
    vector<int> height;
};

void UF::merge(int p, int q) {
    int root_p = find(p), root_q = find(q);
    if (root_p == root_q) return;
    if (height[root_p] >= height[root_q]) {
        parent[root_q] = root_p;
    } else {
        parent[root_p] = root_q;
    }
    if (height[root_p] == height[root_q]) {
        height[root_p] += 1;
    }
}

class Solution {
public:
    bool equationsPossible(vector<string>& equations) {
        // 变量名长度为1且为小写字母，只能是26个字母之一
        UF *puf = new UF(26);
        for (string &eq : equations) {
            // 等式
            if (eq[1] == '=') {
                puf->merge(eq[0]-'a', eq[3]-'a');
            }
        }
        for (string &eq : equations) {
            // 不等式
            if (eq[1] == '!') {
                if (puf->connected(eq[0]-'a', eq[3]-'a')) {
                    return false;
                }
            }
        }
        return true;
    }
};
```
