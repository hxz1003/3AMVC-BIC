**You:**

三种改进的方案新增的复杂度是多少？并且详细介绍一下这三种改进的具体原理和操作，为什么要这样处理，公式的意义是什么都详细介绍一下，再者这部分内容是多个非基准锚点对应一个基准锚点，但是当出现基准锚点多余非基准锚点的时候，是选择某些基准锚点不对应非基准锚点吗？是否能用多个基准锚点去对应非基准锚点呢，给我详细解答一下

* * *

**ChatGPT:**

你这个质疑是关键点：**如果只是把两个非基准锚点直接相加，或者简单平均成五五开，那确实不够合理。**  
所以我前面提到的三种方案，严格说不是“三种新的匹配约束”，而是 **在已经得到多对一/一对多匹配关系之后，如何构造对齐后的锚图列向量**。也就是：先决定“谁对应谁”，再决定“对应后的贡献权重是多少”。

论文和源码现在的实现比较粗。源码在 `aligned.m` 中直接计算 $T_i Z_i$，然后累加到基准锚图上；`DSPFP.m` 最后对每一列取最大值，因此实际是“每个非基准锚点选择一个基准锚点”，没有做组内加权，也没有处理一个基准锚点接收多个非基准锚点时的比例问题。[GitHub+1](https://github.com/mahuimin16/3AMVC/blob/main/aligned.m)

下面统一用论文方向写：

$$Z_i=[z^i_1,\dots,z^i_{m_i}]\in\mathbb{R}^{n\times m_i},  
\qquad  
Z_b=[z^b_1,\dots,z^b_{m_b}]\in\mathbb{R}^{n\times m_b}$$

其中 $z^i_a$ 是第 $i$ 个视图中第 $a$ 个锚点对应的锚图列向量，表示该锚点与全部 $n$ 个样本的关系。3AMVC 公式 9 的目标是把非基准视图 $Z_i$ 对齐到基准视图 $Z_b$，然后在公式 10 中做融合。

3664647.3681273

---

## 1. 先回答你最关心的问题：$m_i<m_b$ 时怎么办？

当：

$$m_i<m_b$$

也就是 **非基准视图锚点更少，基准视图锚点更多**。这通常意味着非基准视图的锚点粒度更粗，基准视图锚点粒度更细。

此时有两种处理方式。

### 方式 A：让部分基准锚点没有非基准视图贡献

这是源码更接近的做法。由于源码每个非基准锚点只选一个基准锚点，所以如果非基准锚点少于基准锚点，就会出现部分基准锚点没有该视图贡献。源码中 `DSPFP.m` 的最终离散化是对每一列取最大值并置 1，因此它保证的是“每个非基准锚点有去处”，不是“每个基准锚点都被覆盖”。[GitHub](https://github.com/mahuimin16/3AMVC/blob/main/DSPFP.m)

优点是保守，不会强行复制粗锚点的信息。缺点是：部分基准锚点在该视图中没有对齐贡献，跨视图融合不充分。

### 方式 B：让一个非基准锚点覆盖多个基准锚点

这是我更推荐的方向，但要注意：**不能简单复制，也不能简单五五开。**

当非基准锚点更少时，合理语义是：

$$\text{一个粗粒度非基准锚点}  
\rightarrow  
\text{多个细粒度基准锚点}$$

也就是一对多。设：

$$\mathcal B_a=\{j\mid \text{基准锚点 }j\text{ 由非基准锚点 }a\text{ 覆盖}\}$$

然后用一个带权矩阵 $Q_i\in\mathbb{R}^{m_i\times m_b}$ 表示分配：

$$\widetilde Z_i=Z_iQ_i$$

其中：

$$Q_i(a,j)>0  
\quad\text{表示非基准锚点 }a\text{ 对基准锚点 }j\text{ 的贡献}$$

如果 $a$ 覆盖多个基准锚点，就要求：

$$\sum_{j\in\mathcal B_a}Q_i(a,j)=1$$

这样做的意义是：**非基准锚点的总关系质量被分配到多个基准锚点上，而不是复制多份。**

这比二值 $P_i$ 更合理，因为二值一对多会造成：

$$z^i_a\rightarrow z^b_{j_1},z^b_{j_2}$$

如果直接复制，那么同一个 $z^i_a$ 会被放大两次；如果直接平均，又默认两个基准锚点五五开，仍然缺乏数据依据。

所以，$m_i<m_b$ 时，我建议的最终处理是：

$$\boxed{  
\text{用多个基准锚点对应一个非基准锚点，但必须用数据驱动权重分配，而不是硬复制。}  
}$$

---

## 2. 三种改进方案的复杂度总览

下面三种方案默认 **容量匹配/分组关系已经得到**。也就是先知道：

当 $m_i>m_b$ 时：

$$\mathcal C_j=\{a\mid \text{非基准锚点 }a\text{ 被分到基准锚点 }j\}$$

当 $m_i<m_b$ 时：

$$\mathcal B_a=\{j\mid \text{基准锚点 }j\text{ 由非基准锚点 }a\text{ 覆盖}\}$$

记：

$$E=|\{(a,j)\mid Q_i(a,j)\ne 0\}|$$

为匹配边数量。多对一时通常 $E=m_i$，一对多覆盖时通常 $E=m_b$。

| 方案 | 主要操作 | 新增复杂度 | 是否新增超参数 | 适合程度 |
| --- | --- | --- | --- | --- |
| 方案 1：覆盖质量加权 | 按锚点覆盖量/质量分配权重 | $O(nm_i+E)$ | 否 | 最简单，但较粗 |
| 方案 2：相似度加权 | 按锚图列向量相似度分配权重 | 若复用已有 $K$：$O(E)$；否则 $O(nE)$，最坏 $O(nm_im_b)$ | 否 | 推荐，性价比最高 |
| 方案 3：局部最小二乘加权 | 用多个非基准锚点最优重构基准锚点 | 多对一：$O(n\sum_j r_j^2+\sum_j r_j^3)$ | 否 | 最严谨，但最复杂 |

其中：

$$r_j=|\mathcal C_j|$$

表示第 $j$ 个基准锚点接收了多少个非基准锚点。如果容量约束比较均衡，则：

$$r_j\approx \frac{m_i}{m_b}$$

那么方案 3 的主要复杂度近似为：

$$O\left(n\frac{m_i^2}{m_b}+\frac{m_i^3}{m_b^2}\right)$$

这仍然是锚点级别操作，不涉及 $n\times n$ 全样本图。相比 3AMVC 本身在 `aligned.m` 中已经计算 $K=Z_bZ_i^\top$、$S_1=Z_bZ_b^\top$、$S_2=Z_iZ_i^\top$，这些本来就有 $O(nm_bm_i)$、$O(nm_b^2)$、$O(nm_i^2)$ 级别计算，三种加权方案的新增量通常小于或接近现有对齐计算。[GitHub](https://github.com/mahuimin16/3AMVC/blob/main/aligned.m)

如果把容量匹配本身也算进去，精确带容量指派可以表述为带容量约束的分配问题。广义指派问题中每个任务分配给一个主体，同时主体满足容量约束，是这类建模的标准形式；但求解器复杂度取决于具体算法。为保持低复杂度，可以用基于相似度矩阵的贪心容量填充，复杂度约为：

$$O(m_im_b\log(m_im_b))$$

它只发生在锚点层面，不涉及样本全图。[DNB](https://d-nb.info/1197702415/34)

---

# 方案 1：覆盖质量加权

## 1.1 多对一情形：$m_i>m_b$

当非基准锚点更多时，多个非基准锚点会被分到同一个基准锚点：

$$\mathcal C_j=\{a_1,a_2,\dots,a_{r_j}\}$$

不能直接写：

$$\widetilde z^i_j  
=  
\sum_{a\in\mathcal C_j} z^i_a$$

因为这样会放大该基准锚点的列向量，也不能简单写：

$$\widetilde z^i_j  
=  
\frac{1}{r_j}  
\sum_{a\in\mathcal C_j} z^i_a$$

因为这默认每个非基准锚点贡献相同。

覆盖质量加权的思想是：**覆盖样本关系更强、质量更高的锚点贡献更大。**

定义：

$$q_a=\|z^i_a\|_1$$

或者如果你已有 BIC/LRT 产生的锚点质量分数，也可以直接用：

$$q_a=\text{Quality}(a)$$

然后：

$$\omega_{aj}  
=  
\frac{q_a}{\sum_{r\in\mathcal C_j}q_r+\epsilon}$$

最终：

$$\widetilde z^i_j  
=  
\sum_{a\in\mathcal C_j}  
\omega_{aj}z^i_a$$

公式意义是：被归并到同一个基准锚点的多个非基准锚点，不再简单相加，而是按覆盖质量加权融合。

复杂度：

$$q_a=\|z^i_a\|_1$$

对所有非基准锚点计算一次需要：

$$O(nm_i)$$

然后对所有匹配边归一化和加权累加需要：

$$O(E)$$

真正生成 $\widetilde Z_i$ 需要把每个非零边对应的列向量加权累加，复杂度是：

$$O(nE)$$

但在多对一硬分组里 $E=m_i$，所以整体是：

$$O(nm_i)$$

## 1.2 一对多情形：$m_i<m_b$

这时一个非基准锚点 $a$ 覆盖多个基准锚点：

$$\mathcal B_a=\{j_1,j_2,\dots,j_{s_a}\}$$

可以按基准锚点的覆盖质量分配：

$$q_j^b=\|z^b_j\|_1$$ $$\rho_{aj}  
=  
\frac{q_j^b}{\sum_{\ell\in\mathcal B_a}q_\ell^b+\epsilon}$$

然后：

$$Q_i(a,j)=\rho_{aj}$$ $$\widetilde Z_i=Z_iQ_i$$

含义是：非基准粗锚点 $a$ 的质量不是复制给多个基准锚点，而是按照这些基准锚点自身覆盖量分配出去。

优点：最简单、无超参数、不会五五开。  
缺点：覆盖量不一定等于“与该非基准锚点更相似”。

---

# 方案 2：锚图列相似度加权

这是我最推荐的主方案，因为它最贴合 3AMVC / FMVACC 的 feature correspondence 思路。

3AMVC 的对齐不是比较原始特征空间中的锚点，而是比较锚图列向量，即“该锚点如何关联全部样本”。因此权重也应该由锚图列向量相似度决定，而不是只看数量或覆盖规模。3AMVC 公式 9 中的 $\|Z_b-Z_iP_i\|_F^2$ 本质上就是要求非基准视图对齐后的锚图列向量接近基准视图。

3664647.3681273

## 2.1 多对一情形：$m_i>m_b$

对于被分到同一个基准锚点 $j$ 的非基准锚点集合：

$$\mathcal C_j$$

计算每个非基准锚点与基准锚点的相似度：

$$s_{aj}  
=  
\left\langle  
\frac{z^i_a}{\|z^i_a\|_2+\epsilon},  
\frac{z^b_j}{\|z^b_j\|_2+\epsilon}  
\right\rangle$$

然后：

$$\omega_{aj}  
=  
\frac{[s_{aj}]_+}  
{\sum_{r\in\mathcal C_j}[s_{rj}]_+ + \epsilon}$$

其中：

$$[s]_{+}=\max(s,0)$$

最终：

$$\widetilde z^i_j  
=  
\sum_{a\in\mathcal C_j}  
\omega_{aj}z^i_a$$

公式意义是：谁的样本关系模式更像基准锚点，谁贡献更大。若两个非基准锚点都映射到同一个基准锚点，不再默认五五开，而是由相似度决定，比如 $0.8/0.2$。

复杂度分两种：

如果源码中已经计算了：

$$K=Z_b^\top Z_i$$

或者在源码方向下计算了 $K=Z_bZ_i^\top$，那么相似度矩阵可以复用。3AMVC 源码 `aligned.m` 本身就计算了 $K=Z_{\text{target}}Z_i^\top$，作为一阶相似度。[GitHub](https://github.com/mahuimin16/3AMVC/blob/main/aligned.m)  
这时新增复杂度主要是对匹配边做归一化：

$$O(E)$$

如果没有现成相似度矩阵，只对匹配边计算相似度，则：

$$O(nE)$$

若计算完整相似度矩阵，则：

$$O(nm_im_b)$$

但这个完整矩阵在对齐阶段通常本来就需要。

## 2.2 一对多情形：$m_i<m_b$

一个非基准锚点 $a$ 覆盖多个基准锚点：

$$\mathcal B_a$$

则对每个被覆盖的基准锚点 $j$ 计算：

$$s_{aj}  
=  
\left\langle  
\frac{z^i_a}{\|z^i_a\|_2+\epsilon},  
\frac{z^b_j}{\|z^b_j\|_2+\epsilon}  
\right\rangle$$

再在 $\mathcal B_a$ 内归一化：

$$\rho_{aj}  
=  
\frac{[s_{aj}]_+}  
{\sum_{\ell\in\mathcal B_a}[s_{a\ell}]_+ + \epsilon}$$

然后：

$$Q_i(a,j)=\rho_{aj}$$ $$\widetilde Z_i=Z_iQ_i$$

这表示：一个粗粒度非基准锚点可以覆盖多个细粒度基准锚点，但不是复制，而是根据相似度把自己的关系质量分配出去。

这回答你的问题：**可以用多个基准锚点去对应一个非基准锚点，而且在 $m_i<m_b$ 时比“部分基准锚点无贡献”更合理；但必须是带权分配，不应是硬复制。**

---

# 方案 3：局部 simplex 最小二乘加权

这是最严谨的一种。

它不只看单独相似度，而是问：**这些被分到同一个基准锚点的非基准锚点，怎样组合才能最接近基准锚点的锚图列向量？**

非负最小二乘本身是标准的约束最小二乘形式，其核心是在线性重构时要求系数非负，避免出现难解释的负贡献。[skscope.readthedocs.io](https://skscope.readthedocs.io/en/latest/gallery/LinearModelAndVariants/non-negative-least-squares.html)

## 3.1 多对一情形：$m_i>m_b$

对每个基准锚点 $j$，已有非基准锚点集合：

$$\mathcal C_j$$

构造矩阵：

$$Z_i^{\mathcal C_j}  
=  
[z^i_a]_{a\in\mathcal C_j}  
\in\mathbb{R}^{n\times r_j}$$

然后求：

$$\omega_j^\star  
=  
\arg\min_{\omega_j}  
\left\|  
z^b_j  
-  
Z_i^{\mathcal C_j}\omega_j  
\right\|_2^2$$ $$\text{s.t.}\quad  
\omega_j\ge 0,\qquad  
\mathbf{1}^\top\omega_j=1$$

最终：

$$\widetilde z^i_j  
=  
Z_i^{\mathcal C_j}\omega_j^\star$$

公式意义是：

* $\omega_j\ge 0$：不允许负贡献，因为负锚点关系没有清晰解释；
* $\mathbf{1}^\top\omega_j=1$：让它成为凸组合，避免幅度膨胀；
* 最小化重构误差：让多个非基准锚点组合后尽量接近基准锚点。

这就从根本上解决了你说的“五五开不合理”问题。两个非基准锚点对应一个基准锚点时，权重可能是：

$$(0.9,0.1)$$

也可能是：

$$(0.55,0.45)$$

完全由数据决定。

复杂度：

对每个 $j$，设：

$$r_j=|\mathcal C_j|$$

形成局部 Gram：

$$H_j=(Z_i^{\mathcal C_j})^\top Z_i^{\mathcal C_j}$$

复杂度：

$$O(nr_j^2)$$

形成线性项：

$$h_j=(Z_i^{\mathcal C_j})^\top z^b_j$$

复杂度：

$$O(nr_j)$$

解一个 $r_j$ 维 simplex 约束二次规划，保守写作：

$$O(r_j^3)$$

所以总复杂度：

$$O\left(n\sum_{j=1}^{m_b}r_j^2+\sum_{j=1}^{m_b}r_j^3\right)$$

若容量较均衡：

$$r_j\approx \frac{m_i}{m_b}$$

则：

$$\sum_j r_j^2  
\approx  
m_b\left(\frac{m_i}{m_b}\right)^2  
=  
\frac{m_i^2}{m_b}$$ $$\sum_j r_j^3  
\approx  
m_b\left(\frac{m_i}{m_b}\right)^3  
=  
\frac{m_i^3}{m_b^2}$$

所以：

$$O\left(  
n\frac{m_i^2}{m_b}  
+  
\frac{m_i^3}{m_b^2}  
\right)$$

如果 $r_j$ 很小，比如 2 或 3，这个代价很低。

## 3.2 一对多情形：$m_i<m_b$

此时反过来，一个非基准锚点 $a$ 对应多个基准锚点：

$$\mathcal B_a$$

这时不能用多个非基准锚点重构一个基准锚点，而应反过来问：

**这个非基准粗锚点应该怎样分解到多个基准细锚点上？**

求：

$$\rho_a^\star  
=  
\arg\min_{\rho_a}  
\left\|  
z^i_a  
-  
Z_b^{\mathcal B_a}\rho_a  
\right\|_2^2$$ $$\text{s.t.}\quad  
\rho_a\ge 0,\qquad  
\mathbf{1}^\top\rho_a=1$$

其中：

$$Z_b^{\mathcal B_a}  
=  
[z^b_j]_{j\in\mathcal B_a}$$

然后令：

$$Q_i(a,j)=\rho^\star_{aj},  
\qquad j\in\mathcal B_a$$

最后：

$$\widetilde Z_i=Z_iQ_i$$

这个公式的含义是：非基准锚点是一个粗粒度关系模式，基准锚点是更细粒度的关系模式。用多个基准锚点的凸组合去解释这个非基准锚点，可以得到它应分配给各个基准锚点的比例。

复杂度类似。设：

$$s_a=|\mathcal B_a|$$

则：

$$O\left(n\sum_{a=1}^{m_i}s_a^2+\sum_{a=1}^{m_i}s_a^3\right)$$

若均衡：

$$s_a\approx \frac{m_b}{m_i}$$

则：

$$O\left(  
n\frac{m_b^2}{m_i}  
+  
\frac{m_b^3}{m_i^2}  
\right)$$

当 $m_b$ 不远大于 $m_i$ 时仍可接受；如果差距很大，方案 2 的相似度加权更稳妥。

---

## 4. 三种方案为什么都要“权重化”，而不是直接相加？

因为 $Z_i$ 的每一列不是普通特征，而是“锚点—样本关系向量”。如果两个非基准锚点都映射到同一个基准锚点，直接相加会改变该列的尺度：

$$z^i_{a_1}+z^i_{a_2}$$

其范数通常大于单个基准锚点列向量。这样会影响后续融合和谱分解。

简单平均：

$$\frac{1}{2}(z^i_{a_1}+z^i_{a_2})$$

虽然解决了尺度问题，但默认两个锚点同等重要，这就是你指出的“五五开不合理”。

所以更好的统一写法是：

$$\widetilde z^i_j  
=  
\sum_{a\in\mathcal C_j}  
\omega_{aj}z^i_a$$

并且：

$$\omega_{aj}\ge 0,\qquad  
\sum_{a\in\mathcal C_j}\omega_{aj}=1$$

这使得 $\widetilde z^i_j$ 是多个非基准锚点的凸组合，不会发生幅度膨胀，且权重由数据决定。

---

## 5. $m_i<m_b$ 时，到底应不应该让某些基准锚点不对应非基准锚点？

我的判断是：

$$\boxed{  
\text{不应作为主方案。}  
}$$

让部分基准锚点没有非基准视图贡献，是源码式的保守做法。它的优点是不会强行复制粗锚点信息，但它的问题是跨视图融合不充分。

更合理的主方案是：

$$\boxed{  
m_i<m_b\text{ 时，让一个非基准锚点以带权方式覆盖多个基准锚点。}  
}$$

但要满足两个条件。

第一，不复制：

$$Q_i(a,j)=1,\quad j\in\mathcal B_a$$

这种写法会把一个非基准锚点复制多次，不推荐。

第二，要分配：

$$\sum_{j\in\mathcal B_a}Q_i(a,j)=1$$

这样一个非基准锚点的总贡献被拆分到多个基准锚点上，而不是被重复使用。

因此，$m_i<m_b$ 的推荐公式是：

$$\widetilde Z_i=Z_iQ_i$$ $$Q_i(a,j)\ge 0$$ $$Q_i(a,j)=0,\quad j\notin\mathcal B_a$$ $$\sum_{j\in\mathcal B_a}Q_i(a,j)=1$$

其中 $Q_i(a,j)$ 可由相似度或局部最小二乘得到。

---

## 6. 最推荐的实际版本

如果你要放进论文主方法，我建议不要采用方案 1 作为最终主方案，因为它太粗。方案 3 最严谨，但复杂度和实现都更重。最均衡的是方案 2：

### 当 $m_i>m_b$：

$$\mathcal C_j=\{a\mid a\rightarrow j\}$$ $$s_{aj}  
=  
\frac{(z^i_a)^\top z^b_j}  
{\|z^i_a\|_2\|z^b_j\|_2+\epsilon}$$ $$\omega_{aj}  
=  
\frac{[s_{aj}]_+}  
{\sum_{r\in\mathcal C_j}[s_{rj}]_+ + \epsilon}$$ $$\widetilde z^i_j  
=  
\sum_{a\in\mathcal C_j}  
\omega_{aj}z^i_a$$

### 当 $m_i<m_b$：

$$\mathcal B_a=\{j\mid a\rightarrow j\}$$ $$s_{aj}  
=  
\frac{(z^i_a)^\top z^b_j}  
{\|z^i_a\|_2\|z^b_j\|_2+\epsilon}$$ $$\rho_{aj}  
=  
\frac{[s_{aj}]_+}  
{\sum_{\ell\in\mathcal B_a}[s_{a\ell}]_+ + \epsilon}$$ $$Q_i(a,j)=\rho_{aj}$$ $$\widetilde Z_i=Z_iQ_i$$

这个版本的优点是：

* 不新增超参数；
* 不直接相加；
* 不默认五五开；
* 可以处理多对一；
* 也可以处理一对多；
* 复杂度基本可以复用现有相似度矩阵；
* 和 3AMVC 的 feature correspondence 逻辑一致。

最终一句话：

**当多个非基准锚点对应一个基准锚点时，不应直接相加或平均，而应做数据驱动的凸组合；当基准锚点多于非基准锚点时，也不应简单让部分基准锚点无贡献，更合理的是让一个非基准锚点以带权方式覆盖多个基准锚点。三种方案中，覆盖质量加权最轻，相似度加权最适合主方法，局部最小二乘最严谨但复杂度最高。**