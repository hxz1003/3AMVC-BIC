# Proposed Method

本文方法依据 MATLAB 实现抽象为一种**BIC 正则化自适应锚点选择的锚点图多视图聚类方法**。整体流程由四个部分组成：第一，在每个视图中通过 BIC 正则化似然比递归二分生成自适应锚点；第二，在每个视图内学习样本到锚点的概率锚图；第三，以单位 BIC 证据增益最大的视图作为基准视图，将其他视图锚图对齐到基准锚点空间并等权融合；第四，对融合锚图的转置矩阵进行奇异值分解，得到样本嵌入并执行 KMeans 得到最终聚类标签。主要代码依据为 `demo_biclr.m`、`Neighbor_BICLR.m`、`biclr/BIC_LR_HBNC.m`、`algo_qp.m`、`aligned.m`、`DSPFP.m` 与 `measure/myNMIACCwithmean.m`。

## 1. 问题定义

设共有 \(n\) 个样本、\(V\) 个视图和 \(c\) 个聚类。数据加载函数 `load_biclr_dataset.m` 将每个视图整理为
\[
X_{\mathrm{raw}}^{(v)}\in\mathbb{R}^{n\times d_v},\qquad v=1,\ldots,V,
\]
其中第 \(i\) 行表示第 \(i\) 个样本在第 \(v\) 个视图下的 \(d_v\) 维特征。主优化函数 `algo_qp.m` 在进入锚图学习前执行
\[
\tilde X^{(v)}=\operatorname{mapstd}\big((X_{\mathrm{raw}}^{(v)})^\top\big)\in\mathbb{R}^{d_v\times n},
\]
因此后续矩阵推导均采用列为样本的方向，即 \(\tilde x_i^{(v)}\) 表示第 \(v\) 个视图中第 \(i\) 个样本的列向量。

目标是在不使用标签参与模型更新的情况下，学习每个样本的聚类标签
\[
\hat y_i\in\{1,\ldots,c\},\qquad i=1,\ldots,n .
\]
代码中的真实标签 \(Y\) 用于确定评价时的类别数 \(c\) 以及计算 ACC、NMI、Purity、Fscore 等指标，不进入锚点生成、锚图优化或跨视图对齐的目标函数。

## 2. 方法整体框架

对每个视图 \(v\)，方法首先在 \(X_{\mathrm{raw}}^{(v)}\) 上执行 BIC-LR 递归二分，得到 \(m_v\) 个叶节点。每个叶节点的样本均值作为锚点，形成锚点矩阵
\[
\Theta^{(v)}=[\theta_1^{(v)},\ldots,\theta_{m_v}^{(v)}]^\top\in\mathbb{R}^{m_v\times d_v}.
\]
随后 `algo_qp.m` 将 \((\Theta^{(v)})^\top\) 作为投影矩阵 \(A^{(v)}\) 的初始化，并学习锚图
\[
Z^{(v)}\in\mathbb{R}^{m_v\times n}.
\]
其中 \(Z_{\cdot i}^{(v)}\) 表示第 \(i\) 个样本与第 \(v\) 个视图中各锚点之间的非负概率关系，满足列和为 1。

在获得所有视图的锚图后，方法根据每个视图最终锚点划分的单位 BIC 证据增益选择基准视图 \(b\)。对于任一非基准视图 \(i\)，先构造锚点结构图
\[
G_b=Z^{(b)}(Z^{(b)})^\top,\qquad
G_i=Z^{(i)}(Z^{(i)})^\top,
\]
以及跨视图锚点关系矩阵
\[
K_{bi}=Z^{(b)}(Z^{(i)})^\top .
\]
`DSPFP.m` 学习硬匹配矩阵 \(P_i\)，`aligned.m` 再用锚图关系向量余弦相似度将硬匹配边转化为加权映射矩阵 \(T_i\)。融合锚图为
\[
S=\frac{1}{V}\left(Z^{(b)}+\sum_{i\ne b}T_iZ^{(i)}\right).
\]
最后对 \(S^\top\) 做经济型奇异值分解，得到样本嵌入 \(U\)，再执行 KMeans 得到聚类标签。

## 3. 数学符号与变量定义

| 符号 | 维度 | 含义 | 代码变量与位置 |
|---|---:|---|---|
| \(n\) | 标量 | 样本数 | `meta.numSamples`, `size(Y,1)` |
| \(V\) | 标量 | 视图数 | `meta.numViews`, `length(X)` |
| \(d_v\) | 标量 | 第 \(v\) 个视图特征维度 | `meta.viewDims(v)` |
| \(c\) | 标量 | 聚类数 | `k`, `numclass` |
| \(X_{\mathrm{raw}}^{(v)}\) | \(n\times d_v\) | 加载后的第 \(v\) 个视图数据 | `load_biclr_dataset.m` |
| \(\tilde X^{(v)}\) | \(d_v\times n\) | 标准化后用于优化的视图数据 | `X{i}=mapstd(X{i}',0,1)` |
| \(\Theta^{(v)}\) | \(m_v\times d_v\) | 第 \(v\) 个视图锚点中心 | `theta`, `thetaall{v}` |
| \(m_v\) | 标量 | 第 \(v\) 个视图锚点数 | `class`, `info.numAnchors` |
| \(A^{(v)}\) | \(d_v\times m_v\) | 第 \(v\) 个视图投影/基矩阵 | `A{v}` |
| \(Z^{(v)}\) | \(m_v\times n\) | 第 \(v\) 个视图锚图 | `Zi{v}` |
| \(\beta\) | 标量 | 锚图正则参数 | `beta` |
| \(\lambda\) | 标量 | 跨视图对齐结构项权重 | `lambda`, `c` in `aligned/DSPFP` |
| \(\lambda_{\mathrm{BIC}}\) | 标量 | BIC 惩罚系数 | `lambdaBIC` |
| \(n_{\min}\) | 标量 | 子节点最小样本数 | `minNodeSize` |
| \(\tau\) | 标量 | BIC-LR 分裂阈值 | `tauSplit` |
| \(\epsilon\) | 标量 | 方差与归一化数值保护项 | `epsVar`, `eps(class(...))` |
| \(G_b,G_i\) | \(m_b\times m_b\), \(m_i\times m_i\) | 锚点结构图 | `S1`, `S2` |
| \(K_{bi}\) | \(m_b\times m_i\) | 跨视图锚点相似矩阵 | `K` |
| \(P_i\) | \(m_b\times m_i\) | DSPFP 硬匹配矩阵 | `hardMatch`, `P` |
| \(T_i\) | \(m_b\times m_i\) | 相似度加权映射矩阵 | `T{i}`, `weightMatrix` |
| \(S\) | \(m_b\times n\) | 融合锚图 | `S`, `Z` |
| \(U\) | \(n\times r\) | SVD 样本嵌入，\(r=\min(n,m_b)\) | `UU`, `U` |
| \(\hat y\) | \(n\times1\) | KMeans 输出聚类标签 | `indx` |

代码中没有显式构造图拉普拉斯矩阵 \(L=D-W\)，也没有视图权重变量。不同视图在最终融合时采用等权平均。

## 4. BIC-LR 自适应锚点生成

### 4.1 节点平方误差统计

对一个节点 \(C=\{x_1,\ldots,x_{n_C}\}\subset\mathbb{R}^d\)，其中心为
\[
\mu_C=\frac{1}{n_C}\sum_{i=1}^{n_C}x_i .
\]
节点内平方误差定义为
\[
W(C)=\sum_{i=1}^{n_C}\|x_i-\mu_C\|_2^2 .
\]
`biclr_node_sse.m` 使用等价形式计算该量：
\[
\begin{aligned}
W(C)
&=\sum_i (x_i-\mu_C)^\top(x_i-\mu_C)\\
&=\sum_i x_i^\top x_i
-2\mu_C^\top\sum_i x_i
+n_C\mu_C^\top\mu_C\\
&=\sum_i x_i^\top x_i
-\frac{1}{n_C}\left\|\sum_i x_i\right\|_2^2 .
\end{aligned}
\]
代码中的
\[
\texttt{sumSq - sum(sumX.^2,2)/n}
\]
正对应上述最后一行。随后使用 `max(real(sse),0)` 避免浮点误差导致理论非负的 SSE 出现微小负值。

### 4.2 单簇球形高斯模型

对于当前节点 \(C\)，单簇假设为
\[
H_0:\quad x_i\sim\mathcal{N}(\mu_0,\sigma_0^2I_d).
\]
其对数似然为
\[
\log L_0
=-\frac{n_Cd}{2}\log(2\pi\sigma_0^2)
-\frac{1}{2\sigma_0^2}\sum_i\|x_i-\mu_0\|_2^2 .
\]
当 \(\mu_0\) 取样本均值时，平方误差为 \(W_0=W(C)\)。球形方差的极大似然估计为
\[
\hat\sigma_0^2=\frac{W_0}{n_Cd}.
\]
代码在方差中加入保护项：
\[
\sigma_0^2=\frac{W_0}{n_Cd}+\epsilon .
\]
`biclr_loglik_single.m` 采用如下受保护似然形式：
\[
\log L_0(C)
=-\frac{n_Cd}{2}\left(\log(2\pi\sigma_0^2)+1\right).
\]
其中 \(\epsilon\) 对应 `epsVar`，用于避免 \(W_0=0\) 时出现 \(\log 0\)。

### 4.3 双簇共享方差模型

对候选划分 \(C=C_1\cup C_2\)，令
\[
n_1=|C_1|,\quad n_2=|C_2|,\quad
\pi_1=\frac{n_1}{n_C},\quad
\pi_2=\frac{n_2}{n_C}.
\]
双簇假设为共享方差的球形高斯混合：
\[
H_1:\quad x\in C_k\sim \mathcal{N}(\mu_k,\sigma_{12}^2I_d),\quad k=1,2.
\]
令 \(W_1=W(C_1)\)、\(W_2=W(C_2)\)，共享方差估计为
\[
\sigma_{12}^2=\frac{W_1+W_2}{n_Cd}+\epsilon .
\]
则 `biclr_loglik_double.m` 中双簇模型的对数似然为
\[
\log L_1(C_1,C_2)
=n_1\log\pi_1+n_2\log\pi_2
-\frac{n_Cd}{2}\left(\log(2\pi\sigma_{12}^2)+1\right).
\]
前两项来自混合比例，后一项来自共享球形方差下的高斯观测似然。

### 4.4 BIC 正则化似然比切分准则

`biclr_best_split.m` 对每个候选二分计算
\[
\operatorname{Score}(C_1,C_2)
=2\big(\log L_1(C_1,C_2)-\log L_0(C)\big)
-\lambda_{\mathrm{BIC}}(d+1)\log n_C .
\]
其中第一项是似然比统计量，衡量双簇模型相对单簇模型的拟合增益；第二项是模型复杂度惩罚，\((d+1)\) 对应新增均值方向与共享方差相关的自由度量级，`lambdaBIC` 控制惩罚强度。

若最优候选满足
\[
\max_{C_1,C_2}\operatorname{Score}(C_1,C_2)>\tau ,
\]
则接受切分；否则停止分裂。默认 `tauSplit=0`，即只有当 BIC 正则化后的统计证据为正时才继续分裂。

### 4.5 候选切分生成与前缀和加速

`biclr_best_split.m` 并不随机枚举划分。它先中心化当前节点样本：
\[
\bar X=X-\mathbf{1}\mu_C^\top,
\]
再计算经济型 SVD：
\[
\bar X=U\Sigma V^\top .
\]
取第一右奇异向量 \(v_1\) 作为投影方向，得到一维投影
\[
p_i=(x_i-\mu_C)^\top v_1 .
\]
样本按 \(p_i\) 升序排序。候选切分点 \(t\) 必须满足
\[
n_{\min}\le t\le n_C-n_{\min},
\]
且相邻投影值存在超过容差的间隔。对排序后的样本，代码预先计算前缀和与前缀平方和。对于左侧前 \(t\) 个样本：
\[
W_{\mathrm{left}}(t)
=\sum_{i=1}^{t}x_i^\top x_i
-\frac{1}{t}\left\|\sum_{i=1}^{t}x_i\right\|_2^2 .
\]
右侧 SSE 同理：
\[
W_{\mathrm{right}}(t)
=\sum_{i=t+1}^{n_C}x_i^\top x_i
-\frac{1}{n_C-t}\left\|\sum_{i=t+1}^{n_C}x_i\right\|_2^2 .
\]
因此每个候选无需重复计算均值和距离，只需由前缀统计量得到 \(W_1,W_2\)。投影仅用于生成候选顺序，所有似然和 SSE 均在原始 \(d\) 维空间计算。

### 4.6 叶节点锚点与视图质量

`BIC_LR_HBNC.m` 对待处理节点执行深度优先递归。若节点停止分裂，则其均值作为锚点：
\[
\theta_k^{(v)}=\frac{1}{|C_k|}\sum_{x_i\in C_k}x_i .
\]
最终得到 \(m_v\) 个锚点、每个锚点的样本数 \(n_k^{(v)}\) 和 SSE \(W_k^{(v)}\)。

为了选择基准视图，`biclr_view_evidence.m` 将整个视图的最终划分视为 \(m_v\) 分量共享方差球形高斯模型。设
\[
W_{\mathrm{part}}^{(v)}=\sum_{k=1}^{m_v}W_k^{(v)},\qquad
\pi_k^{(v)}=\frac{n_k^{(v)}}{n}.
\]
划分模型的对数似然为
\[
\log L_{\mathrm{part}}^{(v)}
=\sum_{k=1}^{m_v}n_k^{(v)}\log\pi_k^{(v)}
-\frac{nd_v}{2}
\left(\log(2\pi\sigma_{\mathrm{part}}^2)+1\right),
\]
其中
\[
\sigma_{\mathrm{part}}^2=\frac{W_{\mathrm{part}}^{(v)}}{nd_v}+\epsilon .
\]
与整视图单簇模型相比，BIC 证据增益为
\[
\Delta_{\mathrm{BIC}}^{(v)}
=2\left(\log L_{\mathrm{part}}^{(v)}-\log L_0^{(v)}\right)
-\lambda_{\mathrm{BIC}}(m_v-1)(d_v+1)\log n .
\]
代码进一步定义单位证据增益
\[
q^{(v)}=\frac{\Delta_{\mathrm{BIC}}^{(v)}}{2nd_v}.
\]
`biclr_select_target_view.m` 选择
\[
b=\arg\max_v q^{(v)}
\]
作为对齐基准视图。为了兼容旧接口，代码将 `qualityScore` 设为 \(-q^{(v)}\)，但基准视图选择仍按 \(q^{(v)}\) 最大执行。

## 5. 视图内锚图学习目标

`algo_qp.m` 中每轮迭代计算
\[
\texttt{term1}=\sum_v\|\tilde X^{(v)}-A^{(v)}Z^{(v)}\|_F^2,
\qquad
\texttt{term2}=\sum_v\|Z^{(v)}\|_F^2,
\]
并记录
\[
\texttt{obj}=\texttt{term1}+\beta\texttt{term2}.
\]
因此根据代码更新式可确定主优化目标为
\[
\min_{\{A^{(v)},Z^{(v)}\}_{v=1}^{V}}
\sum_{v=1}^{V}
\left\|\tilde X^{(v)}-A^{(v)}Z^{(v)}\right\|_F^2
+\beta\sum_{v=1}^{V}\left\|Z^{(v)}\right\|_F^2 ,
\]
满足
\[
Z_{\cdot j}^{(v)}\ge 0,\qquad
\mathbf{1}^\top Z_{\cdot j}^{(v)}=1,\quad j=1,\ldots,n .
\]
当 \(d_v\ge m_v\) 时，代码使用 SVD 更新 \(A^{(v)}\)，该更新对应列正交约束
\[
(A^{(v)})^\top A^{(v)}=I_{m_v}.
\]
当 \(d_v<m_v\) 时，代码使用最小二乘形式更新 \(A^{(v)}\)，这是为了处理无法满足 \(m_v\) 个正交列的维度情形。

Frobenius 范数满足
\[
\|M\|_F^2=\operatorname{Tr}(M^\top M).
\]
因此单视图重构项可写为
\[
\begin{aligned}
\|\tilde X-AZ\|_F^2
&=\operatorname{Tr}\big((\tilde X-AZ)^\top(\tilde X-AZ)\big)\\
&=\operatorname{Tr}(\tilde X^\top\tilde X)
-2\operatorname{Tr}(Z^\top A^\top \tilde X)
+\operatorname{Tr}(Z^\top A^\top A Z).
\end{aligned}
\]
这一展开是后续 \(A\) 与 \(Z\) 更新推导的基础。

## 6. 优化变量更新推导

### 6.1 投影矩阵 \(A^{(v)}\) 的更新

固定 \(Z^{(v)}\) 后，单视图子问题为
\[
\min_A\ \|\tilde X-AZ\|_F^2 .
\]
为简化记号，下文省略视图上标。

#### 6.1.1 最小二乘分支

不加正交约束时，展开目标函数：
\[
\begin{aligned}
J(A)
&=\operatorname{Tr}(\tilde X^\top\tilde X)
-2\operatorname{Tr}(Z^\top A^\top\tilde X)
+\operatorname{Tr}(Z^\top A^\top A Z).
\end{aligned}
\]
利用矩阵求导
\[
\frac{\partial}{\partial A}\|\tilde X-AZ\|_F^2
=2(AZZ^\top-\tilde XZ^\top).
\]
令导数为零：
\[
AZZ^\top=\tilde XZ^\top .
\]
若 \(ZZ^\top\) 可逆，则
\[
A=\tilde XZ^\top(ZZ^\top)^{-1}.
\]
代码使用广义逆增强鲁棒性：
\[
A=\tilde XZ^\top(ZZ^\top)^\dagger .
\]
这对应 `algo_qp.m` 中
```matlab
A{ia} = X{ia}*Zi{ia}'*pinv(Zi{ia}*Zi{ia}');
```
该分支在 `size(A{ia},1)<size(A{ia},2)` 时触发，即 \(d_v<m_v\)。

#### 6.1.2 正交 Procrustes 分支

当 \(d_v\ge m_v\) 时，代码使用 SVD 更新 \(A\)，对应约束
\[
A^\top A=I .
\]
此时
\[
\operatorname{Tr}(Z^\top A^\top A Z)=\operatorname{Tr}(Z^\top Z)
\]
与 \(A\) 无关，因此子问题等价于
\[
\max_{A^\top A=I}\operatorname{Tr}(A^\top \tilde XZ^\top).
\]
令
\[
C=\tilde XZ^\top .
\]
对 \(C\) 做经济型奇异值分解：
\[
C=U\Sigma V^\top .
\]
根据正交 Procrustes 问题的经典结论，
\[
A^\star=UV^\top .
\]
推导如下。记
\[
\operatorname{Tr}(A^\top C)
=\operatorname{Tr}(A^\top U\Sigma V^\top)
=\operatorname{Tr}(V^\top A^\top U\Sigma).
\]
令 \(Q=V^\top A^\top U\)。在 \(A^\top A=I\) 下，\(Q\) 的奇异值不超过 1，因此
\[
\operatorname{Tr}(Q\Sigma)\le \sum_j\sigma_j,
\]
当 \(Q=I\) 时取等号，对应 \(A=UV^\top\)。代码实现为
```matlab
C = X{ia}*Zi{ia}';
[U,~,V] = svd(C,'econ');
A{ia} = U*V';
```

### 6.2 锚图 \(Z^{(v)}\) 的更新

固定 \(A\) 后，单视图子问题为
\[
\min_Z\ \|\tilde X-AZ\|_F^2+\beta\|Z\|_F^2,
\quad
Z_{\cdot j}\ge 0,\quad \mathbf 1^\top Z_{\cdot j}=1.
\]
若采用正交分支 \(A^\top A=I\)，展开单个样本列 \(z_j\) 的目标：
\[
\begin{aligned}
\|\tilde x_j-Az_j\|_2^2+\beta\|z_j\|_2^2
&=\tilde x_j^\top\tilde x_j
-2z_j^\top A^\top\tilde x_j
+z_j^\top A^\top A z_j
+\beta z_j^\top z_j\\
&=\tilde x_j^\top\tilde x_j
-2z_j^\top A^\top\tilde x_j
+(1+\beta)z_j^\top z_j .
\end{aligned}
\]
去掉与 \(z_j\) 无关的常数项，可得
\[
\min_{z_j\in\Delta}
(1+\beta)\|z_j\|_2^2-2z_j^\top A^\top\tilde x_j ,
\]
其中
\[
\Delta=\{z\mid z\ge0,\ \mathbf 1^\top z=1\}.
\]
配方为平方项：
\[
\begin{aligned}
(1+\beta)\|z_j\|_2^2-2z_j^\top A^\top\tilde x_j
&=(1+\beta)
\left\|z_j-\frac{A^\top\tilde x_j}{1+\beta}\right\|_2^2
+\mathrm{const}.
\end{aligned}
\]
因此
\[
z_j^\star=
\Pi_{\Delta}
\left(\frac{A^\top\tilde x_j}{1+\beta}\right),
\]
其中 \(\Pi_\Delta(\cdot)\) 表示投影到概率单纯形。代码中先计算
```matlab
M{a} = (A{a}'*X{a})/(1+beta);
```
再对每一列调用
```matlab
pp(:, ii) = EProjSimplex_new(M{a}(:, ii));
```
得到 \(Z^{(v)}\)。

需要谨慎的是：当 \(d_v<m_v\) 时，代码的 \(A\) 更新为最小二乘分支，未显式保证 \(A^\top A=I\)。严格二次子问题应包含 \(A^\top A\)：
\[
\min_{z_j\in\Delta}
z_j^\top(A^\top A+\beta I)z_j
-2z_j^\top A^\top\tilde x_j .
\]
但实际代码仍使用上述 \((A^\top\tilde x_j)/(1+\beta)\) 的单纯形投影更新。因此，统一写法应以代码实现为准，并说明该闭式投影精确对应正交分支。

### 6.3 单纯形投影推导

`EProjSimplex_new.m` 求解
\[
\min_x\ \frac12\|x-v\|_2^2,
\quad
\text{s.t.}\quad x\ge0,\quad \mathbf 1^\top x=k .
\]
默认 \(k=1\)。构造拉格朗日函数
\[
\mathcal L(x,\lambda,\eta)
=\frac12\|x-v\|_2^2+\lambda(\mathbf 1^\top x-k)-\eta^\top x,
\quad \eta_i\ge0 .
\]
KKT 条件为
\[
x_i-v_i+\lambda-\eta_i=0,\qquad
\eta_i x_i=0,\qquad x_i\ge0 .
\]
若 \(x_i>0\)，则 \(\eta_i=0\)，所以 \(x_i=v_i-\lambda\)；若 \(x_i=0\)，则 \(v_i-\lambda\le0\)。因此解具有截断形式
\[
x_i=\max(v_i-\lambda,0).
\]
\(\lambda\) 由等式约束确定：
\[
\sum_i\max(v_i-\lambda,0)=k .
\]
代码先构造
\[
v_0=v-\bar v\mathbf 1+\frac{k}{m}\mathbf 1,
\]
此时 \(\mathbf 1^\top v_0=k\)。如果 \(v_0\ge0\)，则 \(v_0\) 已在单纯形上，直接返回；否则通过 Newton 迭代求解上式中的 \(\lambda\)，最终返回
\[
x=\max(v_0-\lambda,0).
\]

### 6.4 基准视图选择

固定所有视图锚点划分后，`biclr_select_target_view.m` 从 `infoAll` 中读取单位 BIC 证据增益 \(q^{(v)}\)，选择
\[
b=\arg\max_v q^{(v)}.
\]
若多个视图并列，MATLAB 的 `max` 返回最先出现的位置，即选择编号最小的并列视图。该过程不学习视图权重，也不改变后续等权融合机制。

### 6.5 锚点匹配矩阵 \(P_i\) 的更新

对非基准视图 \(i\)，`aligned.m` 构造
\[
G_b=Z_bZ_b^\top,\quad
G_i=Z_iZ_i^\top,\quad
K=Z_bZ_i^\top .
\]
`DSPFP.m` 优化的最大化目标为
\[
f(P)=\langle K,P\rangle+\lambda\operatorname{Tr}(G_bPG_iP^\top).
\]
其中
\[
\langle K,P\rangle=\sum_{p,q}K_{pq}P_{pq}
\]
鼓励匹配具有相似样本关系的锚点；结构项
\[
\operatorname{Tr}(G_bPG_iP^\top)
\]
鼓励匹配后保持两视图锚点结构的一致性。

对 \(P\) 求梯度。第一项有
\[
\frac{\partial}{\partial P}\langle K,P\rangle=K .
\]
第二项令
\[
h(P)=\operatorname{Tr}(G_bPG_iP^\top).
\]
微分为
\[
\begin{aligned}
dh
&=\operatorname{Tr}(G_b\,dP\,G_iP^\top)
+\operatorname{Tr}(G_bPG_i\,dP^\top)\\
&=\operatorname{Tr}\big((G_b^\top P G_i^\top)^\top dP\big)
+\operatorname{Tr}\big((G_bPG_i)^\top dP\big).
\end{aligned}
\]
由于 \(G_b\) 与 \(G_i\) 均由 \(ZZ^\top\) 得到，是对称矩阵，因此
\[
\nabla_P h(P)=2G_bPG_i .
\]
故
\[
\nabla f(P)=K+2\lambda G_bPG_i .
\]
这与 `DSPFP.m` 中
```matlab
Y(1:n1, 1:n2) = K + 2 * c * A1 * X * A2;
```
一致，其中代码变量 `X` 表示当前连续匹配矩阵。

投影固定点迭代可写为
\[
P^{(t+1)}
=(1-\alpha)P^{(t)}
+\alpha\,\Gamma(\nabla f(P^{(t)})),
\]
代码中 \(\alpha=0.5\)，\(\Gamma(\cdot)\) 由 `gm_dsn.m` 近似实现：先将矩阵补成方阵，再执行 30 轮行列均值调整与非负截断，得到非负归一化近似。随后代码还执行
\[
P^{(t+1)}\leftarrow
\frac{P^{(t+1)}}{\max_{p,q}|P^{(t+1)}_{pq}|}
\]
作为数值尺度归一化。迭代停止条件为
\[
\max_{p,q}|P_{pq}^{(t+1)}-P_{pq}^{(t)}|<10^{-6}
\]
或达到 50 次迭代。

连续矩阵收敛后，代码将其硬化：对每个非基准锚点 \(q\)，选择
\[
p^\star(q)=\arg\max_p P_{pq},
\]
并令
\[
(P_{\mathrm{hard}})_{p^\star(q),q}=1,\quad
(P_{\mathrm{hard}})_{p,q}=0\ (p\ne p^\star(q)).
\]
因此每个非基准视图锚点被分配到一个基准锚点，但一个基准锚点可以接收多个非基准锚点。

### 6.6 相似度加权映射 \(T_i\)

硬匹配只给出离散对应关系。`aligned.m` 进一步计算锚图行向量之间的余弦相似度：
\[
R_{pq}=
\frac{(Z_b)_{p\cdot}(Z_i)_{q\cdot}^\top}
{\|(Z_b)_{p\cdot}\|_2\|(Z_i)_{q\cdot}\|_2+\epsilon}.
\]
代码中分子复用 \(K=Z_bZ_i^\top\)，分母使用行范数乘积，并将非有限值置零。随后取
\[
R_{pq}^{+}=\max(R_{pq},0)
\]
作为非负边权来源。

若非基准视图锚点数不少于基准视图锚点数，代码按每个基准锚点的匹配集合归一化：
\[
T_{pq}=
\frac{R_{pq}^{+}}
{\sum_{q'\in\mathcal N(p)}R_{pq'}^{+}},
\qquad q\in\mathcal N(p).
\]
若非基准视图锚点数少于基准视图锚点数，代码先为未覆盖的基准锚点补充最相似的非基准锚点，再按每个非基准锚点覆盖的基准集合归一化：
\[
T_{pq}=
\frac{R_{pq}^{+}}
{\sum_{p'\in\mathcal B(q)}R_{p'q}^{+}},
\qquad p\in\mathcal B(q).
\]
若某组相似度和为零或出现非有限值，`normalize_edge_weights` 使用均匀权重。该处理保证加权映射非负，并避免除零。

对齐后的锚图为
\[
\bar Z_i=T_iZ_i\in\mathbb{R}^{m_b\times n}.
\]
随后 `normalize_anchor_graph_columns` 对每列执行
\[
\bar z_{\cdot j}\leftarrow
\frac{\max(\bar z_{\cdot j},0)}
{\max(\mathbf 1^\top\max(\bar z_{\cdot j},0),\epsilon)} .
\]
若某列和无效或过小，代码将该列置为均匀分布。

### 6.7 融合锚图与样本嵌入

对所有视图完成对齐后，`aligned.m` 执行等权融合：
\[
S=\frac{1}{V}\left(Z_b+\sum_{i\ne b}\bar Z_i\right).
\]
之后再次列归一化，保证
\[
S_{\cdot j}\ge0,\qquad \mathbf 1^\top S_{\cdot j}=1 .
\]
`algo_qp.m` 对 \(S^\top\) 做经济型 SVD：
\[
S^\top=U\Sigma V^\top .
\]
输出的 \(U\) 作为样本嵌入。由于 \(S^\top\in\mathbb{R}^{n\times m_b}\)，故
\[
U\in\mathbb{R}^{n\times r},\qquad r=\min(n,m_b).
\]
代码没有截取前 \(c\) 列，而是将经济型 SVD 返回的全部左奇异向量传给评价函数。

## 7. 优化算法流程

**算法 1：BIC-LR 自适应锚点图多视图聚类**

**输入：** 多视图数据 \(\{X_{\mathrm{raw}}^{(v)}\}_{v=1}^{V}\)，聚类数 \(c\)，参数 \(\beta,\lambda,\lambda_{\mathrm{BIC}},n_{\min},\tau,\epsilon\)，最大主迭代次数 50。

**初始化：**

1. 对每个视图 \(v\)，在 \(X_{\mathrm{raw}}^{(v)}\) 上执行 BIC-LR 递归二分，得到锚点矩阵 \(\Theta^{(v)}\)、锚点节点标签与节点 SSE。
2. 计算每个视图的单位 BIC 证据增益 \(q^{(v)}\)，选择 \(b=\arg\max_v q^{(v)}\)。
3. 在 `algo_qp.m` 中令 \(A^{(v)}=(\Theta^{(v)})^\top\)，并将 \(X_{\mathrm{raw}}^{(v)}\) 转置、标准化为 \(\tilde X^{(v)}\)。
4. 计算 \(M^{(v)}=(A^{(v)})^\top\tilde X^{(v)}\)，逐列投影到概率单纯形，得到初始 \(Z^{(v)}\)。

**重复直到满足停止准则：**

1. 固定 \(Z^{(v)}\)，对每个视图更新 \(A^{(v)}\)。若 \(d_v<m_v\)，使用最小二乘广义逆；否则使用 SVD Procrustes 解。
2. 固定 \(A^{(v)}\)，计算
   \[
   M^{(v)}=\frac{(A^{(v)})^\top\tilde X^{(v)}}{1+\beta},
   \]
   并逐列投影得到 \(Z^{(v)}\)。
3. 计算主优化目标
   \[
   J=\sum_v\|\tilde X^{(v)}-A^{(v)}Z^{(v)}\|_F^2+\beta\sum_v\|Z^{(v)}\|_F^2.
   \]
4. 若迭代次数大于 9 且相邻目标相对变化小于 \(10^{-6}\)，或目标值小于 \(10^{-10}\)，则停止。

**对齐与融合：**

1. 对每个非基准视图 \(i\)，构造 \(G_b,G_i,K_{bi}\)。
2. 通过 DSPFP 更新连续匹配矩阵并硬化为 \(P_i\)。
3. 根据锚图余弦相似度构造加权映射 \(T_i\)，得到对齐锚图 \(T_iZ^{(i)}\)。
4. 等权平均得到融合锚图 \(S\)，并对其列归一化。

**输出：** 融合锚图 \(S\)、样本嵌入 \(U\)、聚类标签 \(\hat y\)。

## 8. 收敛性与停止准则

代码采用经验停止准则，而未给出理论收敛证明。主优化阶段 `algo_qp.m` 中最大迭代次数为 50，但停止判断写在 `iter>9` 之后：
\[
\mathrm{relChange}
=\left|\frac{J^{(t-1)}-J^{(t)}}{\max(|J^{(t-1)}|,\epsilon)}\right|.
\]
当
\[
t>9,\qquad
\mathrm{relChange}<10^{-6}
\]
或 \(J^{(t)}<10^{-10}\) 时，主优化停止并进入对齐阶段。由于判断条件包含 `iter>maxIter` 但位于 `iter>9` 的分支内，实际也会在超过最大迭代次数后触发。

DSPFP 阶段也采用经验停止准则：
\[
\max_{p,q}|P_{pq}^{(t+1)}-P_{pq}^{(t)}|<10^{-6}
\]
或达到 50 次迭代。`gm_dsn.m` 内部固定执行 30 轮归一化近似，不根据误差自适应停止。

## 9. 聚类结果生成

`algo_qp.m` 返回样本嵌入 \(U\)。`myNMIACCwithmean.m` 首先对每行做归一化：
\[
\bar u_i=\frac{u_i}{\max(\|u_i\|_2,\epsilon)}.
\]
然后调用 `litekmeans`。默认平方欧氏距离下，KMeans 目标为
\[
\min_{\{\mathcal C_k\},\{\mu_k\}}
\sum_{k=1}^{c}\sum_{i\in\mathcal C_k}\|\bar u_i-\mu_k\|_2^2 .
\]
给定中心时，标签更新为
\[
\hat y_i=\arg\min_k \|\bar u_i-\mu_k\|_2^2 .
\]
给定标签时，中心更新为
\[
\mu_k=\frac{1}{|\mathcal C_k|}\sum_{i\in\mathcal C_k}\bar u_i .
\]
`litekmeans.m` 对空簇进行修正：若某些簇没有样本，则选择当前距离较大的样本补入缺失簇。每次 KMeans 最多迭代 100 次；外层重复次数由 `evalOptions.numRuns` 控制，内部随机初始化重复次数由 `evalOptions.kmeansReplicates` 控制。

## 10. 复杂度分析

以下复杂度根据代码中的主要矩阵运算估计。设第 \(v\) 个视图有维度 \(d_v\)、锚点数 \(m_v\)，基准视图锚点数为 \(m_b\)，主优化迭代次数为 \(T\)，DSPFP 对齐迭代次数为 \(T_p\)，KMeans 迭代次数为 \(T_k\)。

### 10.1 BIC-LR 锚点生成

对一个节点包含 \(s\) 个样本、维度为 \(d_v\)。`biclr_best_split.m` 的主要开销包括：

- 中心化与 SSE 计算：\(O(sd_v)\)；
- 经济型 SVD 求第一主方向：一般可估计为 \(O(s d_v\min(s,d_v))\)；
- 排序投影：\(O(s\log s)\)；
- 前缀和与候选扫描：\(O(sd_v+s)\)。

整棵递归树的复杂度依赖实际分裂结构。若近似平衡且每层都需要 SVD，则可粗略写为各节点代价之和：
\[
O\left(\sum_{\text{node }C} |C|d_v\min(|C|,d_v)+|C|\log |C|\right).
\]
`maxAnchors` 限制了叶节点数量，因此也限制了递归树规模。

### 10.2 视图内锚图学习

每次主迭代中，对第 \(v\) 个视图：

- 计算 \(\tilde X Z^\top\)：\(O(d_v n m_v)\)；
- 计算 \(ZZ^\top\)：\(O(m_v^2 n)\)；
- `pinv(ZZ^T)` 最坏约为 \(O(m_v^3)\)；
- SVD Procrustes 对 \(d_v\times m_v\) 矩阵做经济型 SVD，约为 \(O(d_v m_v^2)\)（当 \(d_v\ge m_v\)）；
- 计算 \(A^\top \tilde X\)：\(O(d_v m_v n)\)；
- 对 \(n\) 个 \(m_v\) 维向量做单纯形投影，若按代码 Newton 迭代次数记为 \(T_s\)，约为 \(O(nm_vT_s)\)。

因此主优化总复杂度可估计为
\[
O\left(
T\sum_{v=1}^{V}
\left(d_vnm_v+m_v^2n+m_v^3+d_vm_v^2+nm_vT_s\right)
\right),
\]
其中某些项只在对应更新分支中出现。

### 10.3 跨视图对齐与融合

对非基准视图 \(i\)：

- 构造 \(K=Z_bZ_i^\top\)：\(O(m_bm_in)\)；
- 构造 \(G_b=Z_bZ_b^\top\)：可对基准视图复用，单次 \(O(m_b^2n)\)；
- 构造 \(G_i=Z_iZ_i^\top\)：\(O(m_i^2n)\)；
- DSPFP 每次迭代计算 \(G_bPG_i\)：约 \(O(m_b^2m_i+m_bm_i^2)\)；
- `gm_dsn` 在 \(m_{\max}\times m_{\max}\) 方阵上固定 30 轮，约 \(O(30m_{\max}^2)\)，其中 \(m_{\max}=\max(m_b,m_i)\)；
- 加权对齐 \(T_iZ_i\)：\(O(m_bm_in)\)。

所有非基准视图合计约为
\[
O\left(
\sum_{i\ne b}
\left[
m_bm_in+m_i^2n
+T_p(m_b^2m_i+m_bm_i^2+30m_{\max}^2)
+m_bm_in
\right]
\right).
\]

### 10.4 SVD 嵌入与 KMeans

融合锚图 \(S\in\mathbb{R}^{m_b\times n}\)，对 \(S^\top\in\mathbb{R}^{n\times m_b}\) 做经济型 SVD。若 \(n\ge m_b\)，复杂度约为
\[
O(nm_b^2).
\]
KMeans 在 \(r\) 维嵌入上运行，单次迭代复杂度约为
\[
O(ncr).
\]
若外层重复次数为 \(R\)，每次内部重复为 \(R_k\)，则评价阶段约为
\[
O(RR_kT_kncr).
\]

## 11. 方法特点总结

根据代码实现，该方法具有以下特点：

1. **自适应锚点数量。** 每个视图通过 BIC 正则化似然比决定是否继续二分，锚点数量由数据结构、\(\lambda_{\mathrm{BIC}}\) 和 \(n_{\min}\) 共同决定，而不是固定为预设常数。
2. **概率型锚图表示。** 每个样本到锚点的关系向量被投影到概率单纯形，保证非负且列和为 1，使锚图具有清晰的分配含义。
3. **锚点级跨视图对齐。** 方法不直接对样本级大矩阵做跨视图匹配，而是在锚点图层面构造结构图与跨视图相似矩阵，降低对齐对象规模。
4. **结构一致性匹配。** DSPFP 目标同时包含锚点关系相似项与锚点结构保持项，使匹配不只依赖单个锚点向量相似度，也考虑锚点之间的整体关系。
5. **相似度加权对齐。** 硬匹配之后，代码使用锚图关系向量余弦相似度对匹配边加权，并处理锚点数不一致时的覆盖问题。
6. **等权融合。** 对齐后的各视图锚图采用等权平均。代码中没有学习视图权重，也没有引入额外质量加权融合参数。
7. **SVD 嵌入后聚类。** 最终聚类不是直接在原始特征上进行，而是在融合锚图诱导的样本嵌入上执行 KMeans。

## 12. 需要作者重点确认的理论表述

1. 主优化目标中是否应在论文中统一加入 \(A^\top A=I\) 约束。代码仅在 \(d_v\ge m_v\) 的 SVD 分支严格对应该约束。
2. 当 \(d_v<m_v\) 时，`pinv` 更新和单纯形投影更新共同构成的优化解释是否需要单独说明为工程兼容分支。
3. `aligned.m` 中相似度加权对齐是否为最终论文主方法的一部分，还是只作为实现增强。
4. `DSPFP.m` 中连续矩阵按最大绝对值缩放的步骤是否需要写入正式算法。
5. 视图质量 \(q^{(v)}\) 目前仅用于选择基准视图，不用于加权融合；若论文希望声明质量感知融合，需要额外代码依据或修改实现。
