# 代码理解报告：BIC-LR + 3AMVC 多视图聚类实现

本文档仅基于 `D:\matlab\3AMVC-BIC\3AMVC-main` 中真实存在的 MATLAB 代码、README 与实验脚本整理。当前主线方法属于**锚点图多视图聚类**与**图学习式多视图聚类**：每个视图先生成自适应锚点并学习样本到锚点的概率锚图，再通过锚点级匹配对齐不同视图，最后等权融合锚图并由 SVD 嵌入执行 KMeans 聚类。代码中未发现端到端参数化模型相关实现。

## 1. 仓库核心任务

- README 说明原项目为 ACM MM 2024 “Automatic and Aligned Anchor Learning Strategy for Multi-View Clustering”的代码，入口为 `demo.m`。
- 当前仓库额外实现了 BIC 正则化似然比锚点选择路径，主入口为 `demo_biclr.m` 与 `run_biclr_grid_search.m`。
- 主任务是无监督多视图聚类。真实标签 `Y` 在代码中用于确定聚类类别数与评价指标，不参与 `BIC_LR_HBNC`、`algo_qp` 和 `aligned` 的优化更新。

## 2. 输入数据格式

- 数据文件位于 `dataset/`，通常为 `.mat` 文件。
- `load_biclr_dataset.m` 要求数据中包含变量 `X`，并自动识别标签字段 `Y`、`y` 或 `gnd`。
- `X` 必须为 cell 数组，`X{v}` 表示第 `v` 个视图。加载后每个视图被整理为 `n × d_v` 的 double 矩阵，即每行一个样本，每列一个特征。
- 若某个视图的矩阵方向为 `d_v × n`，且列数等于标签长度，`load_biclr_dataset.m` 会自动转置，并在 `meta.transposedViews` 中记录。
- 标签会被重映射为连续正整数，映射关系记录在 `meta.labelMap`。

## 3. 多视图数据表示

主流程中存在两个方向约定：

1. 数据加载与锚点选择阶段：`X{v} ∈ R^{n × d_v}`，见 `load_biclr_dataset.m` 与 `Neighbor_BICLR.m`。
2. 主优化阶段：`algo_qp.m` 内执行 `X{i} = mapstd(X{i}',0,1)`，因此优化中使用的视图矩阵为 `d_v × n`。

因此论文符号建议定义原始输入为 `X_raw^{(v)} ∈ R^{n × d_v}`，主优化中的标准化矩阵为 `\tilde X^{(v)} ∈ R^{d_v × n}`。

## 4. 核心算法流程

主线 BIC-LR 版本的调用链为：

```text
demo_biclr.m
  -> load_biclr_dataset.m
  -> Neighbor_BICLR.m
      -> BIC_LR_HBNC.m
          -> biclr_best_split.m
          -> biclr_loglik_single.m
          -> biclr_loglik_double.m
          -> biclr_node_sse.m
          -> biclr_view_evidence.m
  -> biclr_select_target_view.m
  -> algo_qp.m
      -> EProjSimplex_new.m
      -> aligned.m
          -> DSPFP.m
              -> gm_dsn.m
  -> myNMIACCwithmean.m
      -> litekmeans.m
      -> Clustering8Measure.m
```

网格搜索入口为 `run_biclr_grid_search.m`。它将 `lambdaBIC/minNodeSize` 放在外层，先生成或读取锚点缓存；再在 `beta/lambda` 网格内调用 `algo_qp` 与评价函数。

## 5. 主要函数列表及数学操作

| 函数/脚本 | 作用 | 对应数学操作 |
|---|---|---|
| `demo.m` | 原始 3AMVC 演示入口 | 调用原始 `Neighbor` 锚点路径、`algo_qp`、聚类评价 |
| `demo_biclr.m` | BIC-LR 版本演示入口 | 加载数据、逐视图生成 BIC-LR 锚点、选择基准视图、优化锚图并聚类 |
| `load_biclr_dataset.m` | 数据加载与标签整理 | 统一多视图数据方向、标签连续化、可选删类/限样 |
| `Neighbor_BICLR.m` | 单视图 BIC-LR 锚点入口 | 调用递归二分并返回锚点中心、节点 SSE、质量证据 |
| `BIC_LR_HBNC.m` | 递归锚点生成 | 节点二分、停止节点均值作为锚点、记录叶节点统计量 |
| `biclr_best_split.m` | 当前节点最佳二分 | 第一主方向投影、合法切分枚举、BIC 正则化似然比打分 |
| `biclr_loglik_single.m` | 单簇模型似然 | 球形高斯单簇极大似然 |
| `biclr_loglik_double.m` | 双簇模型似然 | 共享方差球形高斯混合模型极大似然 |
| `biclr_node_sse.m` | 节点 SSE | 利用 `sum(X.^2)-||sum(X)||^2/n` 计算簇内平方误差 |
| `biclr_view_evidence.m` | 视图整体质量 | 最终锚点划分相对单簇模型的 BIC 证据增益 |
| `biclr_select_target_view.m` | 基准视图选择 | 选择单位 BIC 证据增益最大的视图 |
| `algo_qp.m` | 3AMVC 主优化 | 交替更新投影矩阵 `A` 与锚图 `Zi`，目标为重构误差加锚图正则 |
| `EProjSimplex_new.m` | 单纯形投影 | 解 `min_x 1/2||x-v||^2, s.t. x>=0, 1^T x=1` |
| `aligned.m` | 多视图锚图对齐与融合 | 构造锚点结构图、调用 DSPFP 匹配、相似度加权、等权融合 |
| `DSPFP.m` | 投影固定点匹配 | 优化 `Tr(K'P)+lambda Tr(G_b P G_i P')` 的锚点匹配矩阵 |
| `gm_dsn.m` | 投影近似 | 对矩阵做固定次数非负双随机归一化近似 |
| `myNMIACCwithmean.m` | 聚类评价 | 行归一化 SVD 嵌入，多次 KMeans，输出 8 个指标 |
| `litekmeans.m` | KMeans | 样本到最近中心分配，中心更新为簇内均值 |
| `run_biclr_grid_search.m` | 参数搜索与缓存 | 搜索 `beta/lambda/lambdaBIC/minNodeSize`，按缓存键复用锚点 |

## 6. 关键代码变量与数学符号映射

| 代码变量 | 数学符号 | 维度 | 含义 | 出现文件 |
|---|---|---|---|---|
| `X{v}`（加载后） | `X_{\mathrm{raw}}^{(v)}` | `n × d_v` | 第 `v` 个视图的原始样本特征矩阵 | `load_biclr_dataset.m`, `Neighbor_BICLR.m` |
| `X{i}`（`algo_qp` 内） | `\tilde X^{(v)}` | `d_v × n` | 转置并标准化后的第 `v` 个视图矩阵 | `algo_qp.m` |
| `Y` | `y` | `n × 1` | 真实标签；用于类别数和评价 | `demo_biclr.m`, `myNMIACCwithmean.m` |
| `k` / `numclass` | `c` | 标量 | 聚类类别数 | `demo_biclr.m`, `myNMIACCwithmean.m` |
| `theta` / `thetaall{v}` | `\Theta^{(v)}` | `m_v × d_v` | 第 `v` 个视图的锚点中心矩阵 | `BIC_LR_HBNC.m`, `algo_qp.m` |
| `label_neighbor` | `\ell^{(v)}` | `n × 1` | 单视图样本所属锚点节点标签 | `Neighbor_BICLR.m` |
| `object` | `W_k^{(v)}` | `m_v × 1` | 每个锚点节点的簇内平方误差 | `BIC_LR_HBNC.m` |
| `num_class` / `anchorSizes` | `n_k^{(v)}` | `m_v × 1` | 每个锚点节点包含的样本数 | `BIC_LR_HBNC.m`, `biclr_view_evidence.m` |
| `lambdaBIC` | `\lambda_{\mathrm{BIC}}` | 标量 | BIC 惩罚系数 | `biclr_best_split.m` |
| `minNodeSize` | `n_{\min}` | 标量 | 子节点最小样本数 | `biclr_best_split.m` |
| `tauSplit` | `\tau` | 标量 | 接受分裂阈值，默认 0 | `BIC_LR_HBNC.m` |
| `epsVar` | `\epsilon` | 标量 | 方差保护项 | `biclr_loglik_single.m` |
| `A{v}` | `A^{(v)}` | `d_v × m_v` | 第 `v` 个视图的投影/基矩阵 | `algo_qp.m` |
| `Zi{v}` | `Z^{(v)}` | `m_v × n` | 第 `v` 个视图样本到锚点的概率锚图 | `algo_qp.m` |
| `beta` | `\beta` | 标量 | 锚图 Frobenius 正则参数 | `algo_qp.m` |
| `lambda` / `c` in `aligned` | `\lambda` | 标量 | 跨视图锚点匹配结构项权重 | `algo_qp.m`, `aligned.m`, `DSPFP.m` |
| `target_view` | `b` | 标量 | 基准视图编号 | `biclr_select_target_view.m`, `aligned.m` |
| `S1` | `G_b` | `m_b × m_b` | 基准视图锚点结构图 `Z_b Z_b^T` | `aligned.m` |
| `S2` | `G_i` | `m_i × m_i` | 非基准视图锚点结构图 `Z_i Z_i^T` | `aligned.m` |
| `K` | `K_{bi}` | `m_b × m_i` | 跨视图锚点关系相似矩阵 `Z_b Z_i^T` | `aligned.m` |
| `hardMatch` / `P` | `P_i` | `m_b × m_i` | DSPFP 得到的硬锚点匹配矩阵 | `DSPFP.m`, `aligned.m` |
| `T{v}` / `weightMatrix` | `T_i` | `m_b × m_i` | 相似度加权后的锚点映射矩阵 | `aligned.m` |
| `S` / `Z`（`aligned` 输出） | `S` | `m_b × n` | 融合后的统一锚图 | `aligned.m`, `algo_qp.m` |
| `UU` / `U` | `U` | `n × r` | 对 `S^T` 做 SVD 得到的样本嵌入，`r=min(n,m_b)` | `algo_qp.m` |
| `indx` | `\hat y` | `n × 1` | KMeans 得到的聚类标签 | `myNMIACCwithmean.m` |

## 7. 根据代码反推的完整优化目标

主线方法可分为三个目标层次。

### 7.1 单视图 BIC-LR 锚点划分目标

对当前节点 `C`，代码比较单簇球形高斯模型与双簇共享方差球形高斯模型。候选二分的得分为：

```math
S(C_1,C_2)=2(\log L_1(C_1,C_2)-\log L_0(C))
-\lambda_{\mathrm{BIC}}(d+1)\log n_C .
```

若最优得分超过 `tauSplit`，则接受分裂；否则停止并将节点均值作为锚点。

### 7.2 视图内锚图学习目标

根据 `algo_qp.m` 中 `obj(iter)=term1+beta*term2`，可确定主优化阶段的视图内目标为：

```math
\min_{\{A^{(v)},Z^{(v)}\}}
\sum_{v=1}^{V}
\left\|\tilde X^{(v)}-A^{(v)}Z^{(v)}\right\|_F^2
+\beta\sum_{v=1}^{V}\left\|Z^{(v)}\right\|_F^2 ,
```

其中 `Z^{(v)}` 的每一列通过 `EProjSimplex_new` 投影到概率单纯形：

```math
Z^{(v)}_{\cdot j}\ge 0,\qquad \mathbf 1^\top Z^{(v)}_{\cdot j}=1 .
```

当 `size(A{v},1) >= size(A{v},2)` 时，`A^{(v)}` 通过 SVD Procrustes 形式更新，等价于使用列正交约束：

```math
(A^{(v)})^\top A^{(v)}=I .
```

当 `d_v < m_v` 时，代码改用 `pinv` 的最小二乘更新，此时没有显式正交约束。该分支是代码中的工程兼容处理。

### 7.3 跨视图锚点对齐目标

`DSPFP.m` 明确记录的最大化目标为：

```math
\max_{P_i}\ 
\langle K_{bi},P_i\rangle
+\lambda\operatorname{Tr}(G_bP_iG_iP_i^\top),
```

其中：

```math
G_b=Z^{(b)}(Z^{(b)})^\top,\quad
G_i=Z^{(i)}(Z^{(i)})^\top,\quad
K_{bi}=Z^{(b)}(Z^{(i)})^\top .
```

代码先用投影固定点迭代得到连续匹配矩阵，再按每一列最大值硬化为 `hardMatch`，随后在 `aligned.m` 中用锚图关系向量的余弦相似度构造加权矩阵 `T_i`，最终融合：

```math
S=\frac{1}{V}\left(Z^{(b)}+\sum_{i\ne b}T_i Z^{(i)}\right),
```

并对 `S` 的每一列重新归一化。

## 8. 每个优化变量、约束与更新方式

| 优化变量 | 约束 | 更新方式 | 代码依据 |
|---|---|---|---|
| 锚点划分叶节点 | 子节点样本数不小于 `minNodeSize`；锚点数不超过 `maxAnchors` | 递归二分；接受 BIC-LR 得分大于 `tauSplit` 的最佳切分 | `BIC_LR_HBNC.m`, `biclr_best_split.m` |
| 锚点中心 `theta` | 无显式优化约束 | 每个叶节点样本均值 | `BIC_LR_HBNC.m` |
| 投影矩阵 `A{v}` | SVD 分支隐含列正交；`pinv` 分支无显式正交约束 | Procrustes SVD 或最小二乘闭式解 | `algo_qp.m` |
| 锚图 `Zi{v}` | 非负、列和为 1 | 对 `(A^T X)/(1+beta)` 逐列做单纯形投影 | `algo_qp.m`, `EProjSimplex_new.m` |
| 匹配矩阵 `P_i` | 由 `gm_dsn` 近似非负双随机投影，硬化后每个非基准锚点匹配一个基准锚点 | 投影固定点迭代；再按列最大值硬化 | `DSPFP.m`, `gm_dsn.m` |
| 加权映射矩阵 `T_i` | 非负；按匹配组内归一化 | 按锚图行向量余弦相似度加权，必要时补足未覆盖基准锚点 | `aligned.m` |
| 融合锚图 `S` | 非负、列和为 1 | 对齐锚图等权平均，再列归一化 | `aligned.m` |
| 样本嵌入 `U` | SVD 左奇异向量天然正交 | 对 `S^T` 做经济型 SVD | `algo_qp.m` |

## 9. 最终聚类标签生成

`algo_qp.m` 返回融合锚图 `S` 的 SVD 嵌入 `U`。`myNMIACCwithmean.m` 对 `U` 做行归一化：

```math
\bar u_i = \frac{u_i}{\max(\|u_i\|_2,\epsilon)} .
```

随后调用 `litekmeans`，默认距离为平方欧氏距离，最大迭代次数为 100，每次内部重复次数由 `kmeansReplicates` 控制。KMeans 得到的标签再由 `Clustering8Measure.m` 与真实标签比较，输出 ACC、NMI、Purity、Fscore、Precision、Recall、AR、Entropy。

代码没有从融合锚图显式构造图拉普拉斯矩阵，也没有调用 `eig` 求解拉普拉斯特征向量；最终嵌入来自 `svd(S','econ')`。

## 10. 不确定或需要谨慎解释的部分

1. `algo_qp.m` 中 `A` 的更新存在两个分支：当 `d_v >= m_v` 时 SVD 解可由正交 Procrustes 推导；当 `d_v < m_v` 时使用 `pinv` 最小二乘。论文中若统一写正交约束，需要说明该约束只严格对应 SVD 分支。
2. `Z` 的单纯形更新精确对应 `A^T A=I` 时的子问题；若进入 `pinv` 分支，代码仍使用相同投影更新，但严格二次项应包含 `A^T A`。该处需要结合原论文确认理论表述。
3. `DSPFP.m` 中 `gm_dsn` 是固定 30 轮的投影近似，并在每次更新后对连续矩阵按最大绝对值缩放。该缩放是代码实现中的数值处理，原论文是否将其写入算法需要确认。
4. `aligned.m` 的相似度加权匹配是当前代码真实实现；它是否属于论文主要贡献或工程增强，需要作者确认。
5. 代码中未发现图拉普拉斯构造、视图权重学习、低秩/稀疏约束、L21 范数、核范数、软阈值化或 ADMM 更新。论文中不应加入这些项，除非另有未纳入仓库的实现。
6. `run_biclr_grid_search.m` 的 `summaryMode='bestACC'` 是评价汇总策略，不是模型优化目标。
