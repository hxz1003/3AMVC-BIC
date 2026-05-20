# 对齐模块进一步优化分析报告

## 1. 当前方法与两篇论文的关系

- FMVACC / Align then Fusion 的公式 8 可以概括为“feature correspondence + structure correspondence”的锚点匹配目标。其核心思想是：不同视图的原始锚点处在不同特征空间，不能直接比较；但每个锚点对应锚图 Z 的一列，该列表示该锚点与所有样本的关系，因此可把锚图列向量作为跨视图可比的关系表示。公式 8 同时使用 ||Z_1 - Z_2 P||_F^2 和 ||S_1 - P^T S_2 P||_F^2，其中 S_i = Z_i^T Z_i。
- 3AMVC 的公式 9 延续 FMVACC 的 feature/structure 两项，但允许各视图自动生成不同数量的锚点 m_i 与 m_b，并选择一个基准视图 b，再将非基准视图对齐到基准视图。3AMVC 的贡献在于 HBNC 自适应锚点选择和基于锚点质量选择基准视图。
- 你当前 markdown 的改进是在 3AMVC 框架内，把 HBNC 中较启发式的继续划分判断替换为 BIC 正则化似然比检验，并用 BIC 证据增益替代原始簇内距离式质量指标选择基准视图，同时保留 3AMVC 的等权融合。
- 明确判断：feature correspondence 项不可删除。它是把不同原始特征空间中的锚点转换到同一样本关系空间的关键桥梁。删除该项后，仅靠结构项会退化为纯锚点内部图匹配，容易失去“这些锚点如何覆盖同一批样本”的一阶对应信息。

参考来源：Wang et al., “Align then Fusion: Generalized Large-scale Multi-view Clustering with Anchor Matching Correspondences,” NeurIPS 2022, https://arxiv.org/abs/2205.15075；Ma et al., “Automatic and Aligned Anchor Learning Strategy for Multi-View Clustering,” ACM MM 2024, DOI: 10.1145/3664647.3681273, https://openreview.net/forum?id=TKRqWQVawP。

## 2. 当前对齐模块中最需要修正的问题

最需要修正的是不同锚点数下 P_i 的匹配约束。若

P_i in {0,1}^{m_i x m_b},
P_i 1_{m_b} = 1_{m_i},
P_i^T 1_{m_i} = 1_{m_b},

则左侧总和分别给出

1_{m_i}^T P_i 1_{m_b} = m_i,
1_{m_b}^T P_i^T 1_{m_i} = m_b。

同一个 P_i 的元素总和不可能同时等于 m_i 和 m_b，除非 m_i = m_b。因此，当 3AMVC 自动生成不同锚点数时，原式若仍写成双边等式约束，在数学上不可行。3AMVC 文本中说要表达一对多或多对一关系，但公式里的双边等式仍是方阵置换约束的写法，需要在论文方法部分显式修正。

更合理且不引入人工超参数的约束是“数据决定的平衡半指派/容量匹配”：

若 m_i >= m_b：

P_i 1_{m_b} = 1_{m_i},
floor(m_i / m_b) 1_{m_b} <= P_i^T 1_{m_i} <= ceil(m_i / m_b) 1_{m_b},
P_i in {0,1}^{m_i x m_b}。

含义：每个非基准锚点只映射到一个基准锚点，每个基准锚点接收近似均衡数量的非基准锚点。

若 m_i < m_b：

P_i^T 1_{m_i} = 1_{m_b},
floor(m_b / m_i) 1_{m_i} <= P_i 1_{m_b} <= ceil(m_b / m_i) 1_{m_i},
P_i in {0,1}^{m_i x m_b}。

含义：每个基准锚点由一个非基准锚点对应，非基准锚点可覆盖多个基准锚点，容量上下界由 m_i 和 m_b 自动给出。

当 m_i = m_b 时，上述两种形式都退化为普通一一置换约束。该修正不新增人工超参数，只把原先不可行的约束改成与“不同锚点数”和“一对多/多对一”叙述一致的形式。

参考来源：3AMVC 公式 9 与其“unequal number of anchors”设定；FMVACC 公式 8 的方阵置换设定；Burkard, Dell'Amico, Martello, “Assignment Problems,” SIAM, 2012, DOI: 10.1137/1.9781611972238；Crouse, “On implementing 2D rectangular assignment algorithms,” IEEE TAES, 2016, DOI: 10.1109/TAES.2016.140952。

## 3. 可行优化建议

### 建议 1：修正矩形/部分匹配约束

- 原问题：原约束 P_i 1 = 1 且 P_i^T 1 = 1 在 m_i != m_b 时不可行，却被用于表达一对多或多对一锚点关系。
- 修改公式：采用第 2 节给出的分情况容量半指派约束。m_i >= m_b 时行和为 1、列容量在 floor(m_i/m_b) 与 ceil(m_i/m_b) 之间；m_i < m_b 时列和为 1、行容量在 floor(m_b/m_i) 与 ceil(m_b/m_i) 之间。
- 是否增加超参数：否。容量由 m_i 与 m_b 自动确定。
- 复杂度变化：约束投影或离散求解比方阵 Hungarian/置换稍复杂，但只作用于锚点数级别。相对 n x n 全图仍很轻。
- 是否建议写进主方法：P0，必须写进主方法。否则方法公式与 3AMVC 不等锚点数设定不一致。
- 是否需要改代码：后续实现时需要检查 aligned / DSPFP 中的投影与离散化是否仍按双随机方阵处理。本轮不改代码。
- 可能风险：过于均衡的容量可能限制真实非均衡锚点对应。若担心这一点，可先保留上界 ceil(.)，下界只要求覆盖非空；但为了不引入超参数，主文建议采用 floor/ceil 的平衡容量，附录可讨论放松版本。
- 参考来源：3AMVC；FMVACC；Crouse 2016；Burkard et al. 2012。

### 建议 2：对齐后锚图行归一化

- 原问题：原始 Z_i 满足 Z_i 1 = 1。若 P_i 是方阵置换，Z_i P_i 仍逐行和为 1。但在矩形一对多场景下，P_i 的行和可能大于 1，因此 Z_i P_i 的行和不再等于 1，融合后的锚图也可能不再是样本到锚点的概率式关系。
- 修改公式：
  R(M)_{pq} = M_{pq} / (sum_j M_{pj} + epsilon)，
  \tilde Z_i = R(Z_i P_i)，
  \tilde Z_b = Z_b。
- 是否增加超参数：否。epsilon 是数值稳定常数，可取机器精度 eps 或项目已有 epsVar，不作为调参对象。
- 复杂度变化：O(n m_b)，远低于锚图学习和结构项计算。
- 是否建议写进主方法：P0/P1。若采用矩形容量匹配，强烈建议写进主方法。
- 是否需要改代码：后续实现需要在每个非基准视图对齐后、融合前做行归一化。本轮不改代码。
- 可能风险：若 P_i 产生极端重复匹配，行归一化会掩盖某些覆盖强度差异。但这比破坏锚图行随机约束更可控。
- 参考来源：3AMVC 与 FMVACC 的锚图约束 Z 1 = 1；von Luxburg, “A Tutorial on Spectral Clustering,” Statistics and Computing, 2007, DOI: 10.1007/s11222-007-9033-z。

### 建议 3：将结构矩阵从原始 Gram 改成归一化结构矩阵

- 原问题：G_i = Z_i^T Z_i 会受到锚点覆盖样本规模、列范数和锚点密度影响。覆盖样本多的锚点会有更大列范数，从而在结构项中天然占优；这不一定表示结构更相似。
- 修改公式：
  D_i = diag(||Z_i(:,1)||_2 + epsilon, ..., ||Z_i(:,m_i)||_2 + epsilon)，
  \hat Z_i = Z_i D_i^{-1}，
  \hat G_i = \hat Z_i^T \hat Z_i。
  这样 \hat G_i 的元素接近锚点样本关系列之间的余弦相似性，更强调相对结构而不是覆盖规模。
- 是否增加超参数：否。epsilon 是数值稳定常数。
- 复杂度变化：列归一化 O(n m_i)，Gram 仍为 O(n m_i^2)。量级不变。
- 是否建议写进主方法：P1，强烈建议。它与“不同视图锚点数不同、覆盖密度不同”的设定高度匹配。
- 是否需要改代码：后续需要把结构项中的 G_i 替换为 \hat G_i。本轮不改代码。
- 可能风险：列范数本身也包含锚点覆盖规模信息，归一化后会弱化这一信息。因此不建议删除 feature 项；feature 项继续保留覆盖关系，structure 项专注相对结构。
- 参考来源：FMVACC 的二阶结构项；normalized graph Laplacian / normalized cut 思想见 Shi and Malik, “Normalized Cuts and Image Segmentation,” IEEE TPAMI, 2000, DOI: 10.1109/34.868688；von Luxburg 2007。

### 建议 4：对 feature 项和 structure 项做尺度归一化

- 原问题：||Z_b - Z_i P_i||_F^2 与 ||G_b - P_i^T G_i P_i||_F^2 的数值尺度会随数据集、锚点数、列范数和结构矩阵规模变化。lambda 被迫同时承担“结构重要性”和“数值尺度校正”两个角色。
- 修改公式：
  L_f(P_i) = ||Z_b - R(Z_i P_i)||_F^2 / (||Z_b||_F^2 + epsilon)，
  L_s(P_i) = ||\hat G_b - P_i^T \hat G_i P_i||_F^2 / (||\hat G_b||_F^2 + epsilon)，
  min_{P_i} L_f(P_i) + lambda L_s(P_i)。
- 是否增加超参数：否。lambda 是原对齐模块已有参数，不是新增参数。
- 复杂度变化：只增加范数计算，O(n m_b + m_b^2)，可忽略。
- 是否建议写进主方法：P1，建议。它能显著提高跨数据集和跨锚点数的尺度可比性。
- 是否需要改代码：后续需要在目标函数和梯度中加入固定分母。本轮不改代码。
- 可能风险：若 denominator 很小，epsilon 会影响数值；但 Z_b 是行随机非零矩阵，正常情况下 ||Z_b||_F^2 不会接近 0。
- 参考来源：FMVACC / 3AMVC 的双项对齐目标；数值尺度归一化与谱图归一化思想见 von Luxburg 2007；多任务损失尺度平衡思想可参考 Chen et al., “GradNorm,” ICML 2018, https://proceedings.mlr.press/v80/chen18a.html。

### 建议 5：使用 feature-only 初始匹配 P_i^(0)

- 原问题：QAP / PFP 类方法对初始化敏感；若直接随机或单位初始化，在 m_i != m_b 时单位阵也不存在。
- 修改公式：
  P_i^(0) = argmin_{P_i in C_i} ||Z_b - R(Z_i P_i)||_F^2，
  其中 C_i 是第 2 节的矩形容量匹配约束集合。
  实现上可等价使用列相似度 K = \bar Z_i^T \bar Z_b 进行矩形线性指派或容量匹配初始化。
- 是否增加超参数：否。
- 复杂度变化：计算相似度 O(n m_i m_b)，线性/容量指派只在锚点数上求解。与后续结构对齐相比成本可控。
- 是否建议写进主方法：P1。它是对齐模块的稳定初始化，不改变最终目标。
- 是否需要改代码：后续需要在求解 P_i 前生成 P_i^(0)。本轮不改代码。
- 可能风险：feature-only 初始化可能偏向样本覆盖相似而忽视结构；但后续 structure 项会修正，因此它适合作为初始化而不是替代完整目标。
- 参考来源：FMVACC 的 feature correspondence；Leordeanu, Hebert, Sukthankar, “An Integer Projected Fixed Point Method for Graph Matching and MAP Inference,” NeurIPS 2009, https://papers.nips.cc/paper/3756-an-integer-projected-fixed-point-method-for-graph-matching-and-map-inference；Crouse 2016。

### 建议 6：数据自适应 lambda_i* 可行，但更适合作为可选改进

- 原问题：手动搜索 lambda 会增加实验负担，而且 lambda 同时承担尺度平衡与结构偏好控制。
- 修改公式：
  先用建议 5 得到 P_i^(0)，再估计
  lambda_i* =
  L_f(P_i^(0)) / (L_s(P_i^(0)) + epsilon)。
  若不使用尺度归一化，也可用原始残差比；但更建议使用 L_f 与 L_s 的归一化版本。
- 是否增加超参数：否。lambda_i* 完全由数据、当前视图和初始匹配决定。
- 复杂度变化：只多一次初始残差计算。
- 是否建议写进主方法：P2。它合理，但建议先作为“自适应对齐权重版本”做消融，不要立即替代主方法中的原始 lambda。原因是 lambda_i* 可能在结构初始残差很小时过大，使后续优化过度偏向结构项。
- 是否需要改代码：后续若采用，需要把固定 lambda 替换为每个视图的 lambda_i*。本轮不改代码。
- 可能风险：若 P_i^(0) 已经使 structure residual 很小，lambda_i* 会被放大；若 feature residual 被异常视图放大，也会影响 lambda_i*。可用尺度归一化缓解，但不建议再引入裁剪阈值，因为裁剪会变成人工超参数。
- 关键判断：
  1. 它比直接用 ||Z_b - Z_i|| / ||G_b - G_i|| 更合理，因为 m_i != m_b 时 Z_b 与 Z_i 不能直接相减，G_b 与 G_i 维度也可能不同。
  2. 必须使用 P_i^(0)，否则不同锚点数下残差不可定义。
  3. 它不增加人工超参数。
  4. 若称为“损失尺度平衡”，写法最简洁；若称为“梯度量级平衡”，则残差比并不是严格梯度平衡。
  5. 对未归一化目标 F(P)=||Z_b-Z_iP||_F^2，梯度为 2 Z_i^T (Z_iP-Z_b)。若 H(P)=||G_b-P^T G_i P||_F^2 且 G_i、G_b 对称，则梯度为 4 G_i P (P^T G_i P - G_b)。严格梯度平衡应使用 ||grad F(P_i^(0))||_F / (||grad H(P_i^(0))||_F + epsilon)，而不是残差比。
- 参考来源：FMVACC / 3AMVC 的 lambda 平衡项；Chen et al. 2018 GradNorm；Kendall, Gal, Cipolla, “Multi-Task Learning Using Uncertainty to Weigh Losses,” CVPR 2018, https://openaccess.thecvf.com/content_cvpr_2018/html/Kendall_Multi-Task_Learning_Using_CVPR_2018_paper.html。

### 建议 7：FGW 只作为理论解释，不作为主实现

- 原问题：现有目标已经同时包含一阶关系表示匹配和二阶结构匹配，容易与最优传输中的 Fused Gromov-Wasserstein 产生概念联系。但完整引入 FGW 会大幅改变算法。
- 修改公式：不修改现有主公式，只在论文解释中说明该目标可视为轻量化 feature-structure matching，与 FGW 同样强调特征项和结构项的联合匹配。
- 是否增加超参数：作为解释不增加。完整 FGW 往往需要边缘分布、熵正则、结构距离定义、partial/unbalanced mass 等额外设计。
- 复杂度变化：作为解释无变化。完整 FGW/Sinkhorn 会引入迭代输运求解，且结构项常涉及四阶交互，复杂度与实现复杂度都不适合当前主线。
- 是否建议写进主方法：P3，只写理论解释，不写成算法模块。
- 是否需要改代码：不需要。
- 可能风险：不能把当前方法夸大为完整 FGW。应表述为“FGW-style”或“受 FGW 启发的轻量化特征-结构匹配解释”。
- 可直接写进论文的中文表述：
  “从最优传输视角看，本文的跨视图锚点对齐目标与 Fused Gromov-Wasserstein 类方法具有一致的建模动机：二者都试图在匹配两个对象集合时同时保持一阶属性相似性和二阶内部结构一致性。不同的是，本文并不求解完整的 FGW 输运问题，而是利用锚图列向量作为锚点在公共样本空间中的关系表示，并在低维锚点集合上学习匹配矩阵。这样既保留了 feature correspondence 与 structure correspondence 的联合约束，又避免了完整 FGW 中边缘分布设计、熵正则参数和高成本 Sinkhorn/OT 迭代，从而符合大规模锚图聚类的低复杂度目标。”
- 参考来源：Vayer et al., “Optimal Transport for structured data with application on graphs,” ICML 2019, https://icml.cc/virtual/2019/oral/4404；Vayer et al., “Fused Gromov-Wasserstein distance for structured objects,” arXiv:1811.02834；Cuturi, “Sinkhorn Distances,” NeurIPS 2013, https://papers.nips.cc/paper/4927-sinkhorn-distances-lightspeed-computation-of-optimal-transport。

### 建议 8：继续保留等权融合，不再加入质量加权或残差加权

- 原问题：质量加权融合会把“锚点选择质量”“对齐质量”“视图融合权重”混在一起，改变 3AMVC 原始变量和融合公式。
- 修改公式：保留
  Z_aligned = (1/V) sum_v \tilde Z_i。
- 是否增加超参数：否。
- 复杂度变化：无。
- 是否建议写进主方法：P1，建议当前阶段继续保留等权融合。
- 是否需要改代码：不需要。
- 可能风险：等权融合不能显式降低低质量视图权重。但你的 BIC 证据增益已经用于选择更可靠的基准视图，当前优化重点应放在 P_i、G_i、归一化和约束修正上。此时再加入加权融合会增加消融因素，削弱论文主线。
- 参考来源：3AMVC 公式 10 的等权融合；FMVACC 的 aligned fusion 设定；多视图图融合中权重学习易引入额外变量，可对照 Nie et al. self-weighted MVC 系列思想，但当前不建议引入。

### 建议 9：容量归一化的结构收缩项

- 原问题：若 m_i > m_b，多对一映射会把多个源锚点聚合到一个基准锚点。直接使用 P_i^T \hat G_i P_i 可能随列容量增大而放大结构值。
- 修改公式：
  c_i(P)=P_i^T 1_{m_i}，
  C_i(P)=diag(c_i(P)+epsilon)，
  S_i(P)=C_i(P)^{-1/2} P_i^T \hat G_i P_i C_i(P)^{-1/2}。
  将结构项改为 ||\hat G_b - S_i(P)||_F^2。
- 是否增加超参数：否。容量由 P_i 决定。
- 复杂度变化：只增加 O(m_b^2) 的对角缩放。
- 是否建议写进主方法：P2。若实验发现 m_i 与 m_b 差异较大，建议采用；若希望最小改动，可先只做建议 3 的 \hat G。
- 是否需要改代码：后续需要在结构项和梯度中加入容量归一化。本轮不改代码。
- 可能风险：S_i(P) 使结构项比原 P^T G P 多一层 P 相关归一化，推导梯度更复杂。可以先在离散候选或最终目标评价中使用，优化阶段仍用简化结构项。
- 参考来源：normalized quotient graph / normalized cut 思想见 Shi and Malik 2000、von Luxburg 2007；容量匹配见 Burkard et al. 2012。

## 4. 上述方向之外的跨领域可参考优化

### 方向 1：计算机视觉 + mutual nearest neighbor / ratio test

- 来源领域：局部特征匹配与图像检索。
- 核心思想：可靠匹配通常需要双向一致性检查；Lowe 的 ratio test 用最近邻和次近邻距离比筛掉歧义匹配。
- 对 3AMVC 对齐模块的可能迁移方式：可用 mutual nearest neighbor 生成 feature-only 初始匹配的可信种子，或用于检查 P_i 的离散化结果是否出现大量单向热门匹配。ratio test 本身需要阈值，不建议作为主方法；双向一致性不需要阈值，更适合当前限制。
- 是否增加超参数：MNN 不增加；ratio test 增加阈值，不建议主用。
- 复杂度变化：计算列相似度后做双向 argmax，O(m_i m_b)。
- 是否建议采用：建议采用 MNN 作为诊断或初始化辅助；不建议采用 ratio threshold 作为主算法。
- 不建议采用的情况：若最终采用容量匹配且一对多是合理现象，严格 MNN 可能过度稀疏。
- 参考来源：Lowe, “Distinctive Image Features from Scale-Invariant Keypoints,” IJCV 2004, DOI: 10.1023/B:VISI.0000029664.99615.94, https://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf。

### 方向 2：信息检索 / 推荐系统 + hubness 抑制

- 来源领域：高维最近邻搜索、推荐系统和信息检索。
- 核心思想：高维空间中某些点会成为大量查询的“热门近邻”，导致匹配塌缩。双向检索一致性、列归一化和容量约束都能缓解 hubness。
- 对 3AMVC 对齐模块的可能迁移方式：使用列 L2 归一化的 \hat Z、平衡容量约束和 MNN 诊断，防止某个锚点被过度匹配。
- 是否增加超参数：否。
- 复杂度变化：列归一化 O(nm)，MNN O(m_i m_b)。
- 是否建议采用：建议采用其中的列归一化和容量约束；hubness 统计可作为诊断指标，不必写入主公式。
- 不建议采用的情况：不要引入 k-occurrence 阈值或局部缩放阈值，否则会增加人工超参数。
- 参考来源：Radovanović, Nanopoulos, Ivanović, “Hubs in Space: Popular Nearest Neighbors in High-Dimensional Data,” JMLR 2010, https://jmlr.org/papers/v11/radovanovic10a.html。

### 方向 3：图论 + normalized adjacency / random-walk transition

- 来源领域：谱聚类、normalized cut、随机游走图归一化。
- 核心思想：原始邻接或 Gram 矩阵容易受节点度影响；归一化邻接 D^{-1/2} A D^{-1/2} 或随机游走矩阵 D^{-1}A 更关注相对连接结构。
- 对 3AMVC 对齐模块的可能迁移方式：把 G_i = Z_i^T Z_i 替换为 \hat G_i，或在多对一结构收缩时使用 C^{-1/2} P^T \hat G_i P C^{-1/2}。
- 是否增加超参数：否。
- 复杂度变化：与原 Gram 同阶。
- 是否建议采用：建议采用，是最贴合当前结构项的跨领域启发。
- 不建议采用的情况：不建议构造 n x n 样本图，也不建议引入 PageRank 阻尼系数，因为阻尼系数会成为新参数。
- 参考来源：Shi and Malik 2000；von Luxburg 2007；Page et al., “The PageRank Citation Ranking: Bringing Order to the Web,” Stanford Technical Report, 1999。

### 方向 4：组合优化 + rectangular assignment / b-matching / min-cost flow

- 来源领域：线性指派、矩形指派、容量约束匹配、最小费用流。
- 核心思想：当两侧元素数量不同，双随机置换不是正确可行域；应使用矩形指派、半指派或带容量的二部图匹配。
- 对 3AMVC 对齐模块的可能迁移方式：用第 2 节容量约束定义 P_i 的可行域；feature-only P_i^(0) 可通过矩形指派或最小费用流求解。
- 是否增加超参数：否，容量由 m_i 和 m_b 自动给出。
- 复杂度变化：锚点级组合优化，通常远小于样本级图构造。
- 是否建议采用：必须采用约束修正；求解器形式可按现有代码能力选择。
- 不建议采用的情况：不建议引入需要手动设定 unmatched penalty 的 partial matching，因为该 penalty 是新超参数。
- 参考来源：Burkard et al. 2012；Crouse 2016；SciPy linear_sum_assignment 文档说明了矩形指派问题与 Crouse 2016，https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html。

### 方向 5：多任务学习 + loss/gradient balancing

- 来源领域：多任务学习中的多损失平衡。
- 核心思想：不同损失项量纲和梯度大小不同，直接相加会让大尺度项主导优化。
- 对 3AMVC 对齐模块的可能迁移方式：采用建议 4 的损失尺度归一化；lambda_i* 可作为数据自适应损失尺度平衡版本。若要严格讲梯度平衡，应使用梯度范数比，而不是残差比。
- 是否增加超参数：损失尺度归一化不增加；完整 GradNorm 有额外不对称参数，不建议照搬。
- 复杂度变化：尺度归一化几乎无额外成本；梯度范数估计成本也较小，但推导更复杂。
- 是否建议采用：建议采用损失尺度归一化；lambda_i* 可选；不建议完整引入 GradNorm。
- 不建议采用的情况：如果论文主线强调与 3AMVC 兼容，避免引入动态训练式权重更新。
- 参考来源：Chen et al. 2018 GradNorm；Kendall et al. 2018 uncertainty weighting。

### 方向 6：数值线性代数 + 预条件与尺度不变目标

- 来源领域：矩阵预条件、范数归一化、尺度不变优化。
- 核心思想：先把不同项缩放到相近数值尺度，可改善优化稳定性，减少数据集间调参依赖。
- 对 3AMVC 对齐模块的可能迁移方式：列 L2 归一化、损失分母归一化、容量归一化都属于低成本预条件。
- 是否增加超参数：否。
- 复杂度变化：低阶矩阵缩放，几乎不改变复杂度。
- 是否建议采用：建议采用。
- 不建议采用的情况：不要引入需要估计额外投影维度或学习预条件矩阵的方法。
- 参考来源：von Luxburg 2007；Golub and Van Loan, “Matrix Computations,” 4th ed., Johns Hopkins University Press, 2013。

### 方向 7：实体匹配 / 数据库 + blocking 与一致性检查

- 来源领域：实体解析、记录链接、候选生成。
- 核心思想：先用廉价相似度生成候选，再做较贵匹配；匹配后检查双向一致性。
- 对 3AMVC 对齐模块的可能迁移方式：只把 feature-only P_i^(0) 作为候选/初始化，不做 top-k blocking，因为 top-k 的 k 是新超参数。可用 MNN 或容量约束做无阈值一致性检查。
- 是否增加超参数：MNN 不增加；top-k blocking 会增加，不建议。
- 复杂度变化：MNN 很低；top-k 可降复杂度但不符合限制。
- 是否建议采用：只建议采用无阈值一致性检查，不建议主方法加入 blocking。
- 不建议采用的情况：当锚点数本来较小，blocking 的收益有限，且会引入额外边界条件。
- 参考来源：Lowe 2004；Crouse 2016；Radovanović et al. 2010。

### 方向 8：最优传输 + partial / unbalanced OT / FGW

- 来源领域：最优传输、图匹配、结构对象距离。
- 核心思想：用 coupling 表示跨集合匹配，同时考虑特征代价与结构代价。
- 对 3AMVC 对齐模块的可能迁移方式：只保留理论解释：当前 feature + structure 目标可解释为轻量化 FGW-style matching。
- 是否增加超参数：作为解释不增加；完整 partial/unbalanced/entropy OT 会增加质量边缘、未匹配惩罚、熵正则等设计。
- 复杂度变化：作为解释无变化；完整 OT/FGW 增加明显。
- 是否建议采用：只建议作为理论解释，P3。
- 不建议采用的情况：不作为当前主实现，不引入 Sinkhorn。
- 参考来源：Vayer et al. 2019；Cuturi 2013。

## 5. 最推荐的最终公式版本

最适合写进论文主方法的版本应保持 3AMVC 原始等权融合，同时修正 P_i 可行域，并对结构与损失尺度做低成本归一化。

对每个非基准视图 i，定义

\tilde Z_i(P_i) = R(Z_i P_i)，
\tilde Z_b = Z_b，
D_i = diag(||Z_i(:,a)||_2 + epsilon)_a，
\bar Z_i = Z_i D_i^{-1}，
\hat G_i = \bar Z_i^T \bar Z_i。

若采用容量归一化结构收缩，则

C_i(P_i)=diag(P_i^T 1_{m_i} + epsilon)，
S_i(P_i)=C_i(P_i)^{-1/2} P_i^T \hat G_i P_i C_i(P_i)^{-1/2}。

主目标建议写为：

min_{P_i in C_i}
  ||Z_b - R(Z_i P_i)||_F^2 / (||Z_b||_F^2 + epsilon)
  + lambda * ||\hat G_b - S_i(P_i)||_F^2 / (||\hat G_b||_F^2 + epsilon)。

其中 C_i 是第 2 节的矩形容量匹配可行域。若暂不采用容量归一化结构收缩，可令 S_i(P_i)=P_i^T \hat G_i P_i。

融合仍为：

Z_aligned = (1/V) [ Z_b + sum_{i != b} R(Z_i P_i) ]。

lambda 不是新增超参数，而是 3AMVC / FMVACC 原始对齐模块已有参数。若希望进一步减少搜索，可把 lambda 替换为

lambda_i* = L_f(P_i^(0)) / (L_s(P_i^(0)) + epsilon)，

其中 P_i^(0) 是 feature-only 初始匹配。但我建议先把 lambda_i* 作为可选版本做消融，不要直接作为唯一主方法。

## 6. 与我当前 markdown 的具体修改建议

- 3.6 跨视图锚图对齐：
  1. 替换式 (60) 的双边等式约束，改为第 2 节的分情况矩形容量匹配约束。
  2. 在 G 定义处加入列归一化结构 \hat G_i。
  3. 在 Z_i P_i 后加入 R(Z_i P_i) 行归一化。
  4. 在目标函数中加入 feature / structure 的尺度归一化分母。
  5. 可选加入 P_i^(0) 的 feature-only 初始化说明。

- 3.7 等权锚图融合：
  1. 保留等权融合。
  2. 将原来的 Z_i P_i 改成 R(Z_i P_i)。
  3. 明确说明不引入质量权重或残差权重，以保持与 3AMVC 原始融合公式兼容。

- 3.9 完整目标函数视角：
  1. 将跨视图对齐目标替换为归一化后的 L_f + lambda L_s。
  2. 明确 C_i 为矩形容量匹配可行域。
  3. 如采用 lambda_i*，写成可选 parameter-free alignment variant，而不是主线必要项。

- 3.10 算法描述：
  1. 在学习 P_i 前加入 feature-only 初始匹配 P_i^(0)。
  2. 在求解 P_i 时写明使用矩形容量约束。
  3. 在融合前加入行归一化步骤。
  4. 若保留 lambda 搜索，说明 lambda 是原对齐参数；若使用 lambda_i*，说明由 P_i^(0) 自动估计。

- 3.11 复杂度分析：
  1. 增加列归一化 O(n m_i)。
  2. 归一化 Gram 仍为 O(n m_i^2)。
  3. 行归一化为 O(n m_b)。
  4. feature-only 初始化相似度为 O(n m_i m_b)，匹配求解发生在锚点数级别。
  5. 强调没有构造 n x n 全样本图。

- 参考文献部分：
  1. 保留 FMVACC 与 3AMVC。
  2. 增加 rectangular assignment / assignment problem 文献：Burkard et al. 2012；Crouse 2016。
  3. 增加 normalized graph / spectral clustering 文献：Shi and Malik 2000；von Luxburg 2007。
  4. 增加 PFP / graph matching 文献：Leordeanu et al. 2009。
  5. 增加 FGW / OT 解释文献：Vayer et al. 2019；Cuturi 2013。
  6. 如写 loss balancing，可引用 Chen et al. 2018 或 Kendall et al. 2018，但需说明只借鉴尺度平衡思想。

## 7. 消融实验建议

最小消融组合建议如下：

1. A0：原当前版本
   BIC-LR 锚点选择 + BIC 证据基准视图 + 原对齐公式 + 等权融合。
   作用：作为当前 markdown 的基线。
   必须做。

2. A1：修正矩形匹配约束
   只替换 P_i 可行域，不改 G 和损失尺度。
   作用：验证数学约束修正本身的影响。
   必须做。

3. A2：A1 + 对齐后行归一化
   使用 R(Z_i P_i) 后再融合。
   作用：验证行随机锚图约束是否影响最终聚类。
   必须做，尤其当 m_i < m_b 时。

4. A3：A2 + 归一化结构矩阵 \hat G
   将 G_i 替换为 \hat G_i。
   作用：验证结构项从覆盖规模转向相对结构是否有收益。
   必须做。

5. A4：A3 + 损失尺度归一化
   使用 L_f + lambda L_s。
   作用：验证跨数据集尺度稳定性。
   强烈建议做。

6. A5：A4 + lambda_i*
   用 P_i^(0) 估计每个视图的自适应 lambda_i*。
   作用：验证是否能减少 lambda 搜索。
   可选做，不建议一开始作为主结果唯一版本。

若实验预算有限，最小必须组合是 A0、A1、A2、A3、A4。A5 可作为附录或后续增强。

## 8. 最终结论

P0：必须修正
- 不同锚点数下的 P_i 双边等式约束不可行，必须改成矩形容量匹配/半指派约束。
- 若采用一对多或多对一匹配，融合前必须保证对齐锚图仍满足行归一化。
- feature correspondence 项不可删除。

P1：强烈建议
- 使用列归一化结构矩阵 \hat G_i。
- 对 feature 与 structure 损失做尺度归一化。
- 使用 feature-only P_i^(0) 初始化匹配。
- 继续保留等权融合，不引入质量加权或残差加权。

P2：可选
- 使用容量归一化结构收缩 C^{-1/2} P^T \hat G_i P C^{-1/2}。
- 使用数据自适应 lambda_i* 替代手动 lambda 搜索。建议作为可选版本先消融。
- MNN 一致性检查可作为初始化诊断。

P3：只作为理论解释
- FGW / partial OT / unbalanced OT 只用于解释 feature-structure matching 的理论背景，不作为当前主实现。
- PageRank、完整图核、复杂 Sinkhorn、深度网络、n x n 全图重构均不适合作为当前主线。

## 9. 输出文件要求

报告文件保存路径：
D:\matlab\3AMVC-BIC\alignment_optimization_analysis_report.txt

本报告仅新增上述 txt 文件；不修改代码、论文主文件、markdown 或实验脚本。

## 10. 2024-2026 最新文献补充与对当前方法的影响

根据进一步联网检索，2024-2026 年多视图锚图聚类领域的趋势非常明确：最新工作普遍不再满足于“固定锚点数 + 简单线性融合”，而是强调锚点质量、视图间锚点或图结构对齐、不同大小锚图融合、局部/全局一致性以及锚图高阶相关性。这些趋势支持你当前 BIC-LR + BIC 证据基准视图选择的方向，也进一步说明对齐模块中 P_i 约束、结构归一化和尺度归一化是值得优先修正的关键点。

### 10.1 与当前工作最相关的近年文献

1. Zhang et al., “Learning Cluster-Wise Anchors for Multi-View Clustering,” AAAI 2024.
   该文强调锚点不仅要多样，还要具有簇级语义结构，显式建模 inter-cluster diversity 与 intra-cluster consistency。对你的启发是：BIC-LR 生成的叶节点锚点可以被解释为数据驱动的簇级候选锚点；后续对齐时，结构项不应只看原始 Gram 强度，还应看归一化后的相对簇结构。建议用于支持“归一化结构矩阵 \hat G_i”和“minNodeSize 抑制极小簇”的合理性，而不建议引入它的预定义共识簇指示矩阵，因为这会改变你的无参锚点选择叙事。
   来源：AAAI 2024, DOI: 10.1609/aaai.v38i15.29609。

2. Liu et al., “Learn from View Correlation: An Anchor Enhancement Strategy for Multi-view Clustering,” CVPR 2024.
   该文提出 plug-and-play 的视图相关性锚点增强，认为相似视图间的锚点关系可互相改进。对你的启发是：feature-only P_i^(0) 可以被解释为一种低成本的跨视图关系估计，用于初始化后续结构对齐；但不建议把该文的完整 view graph enhancement 加入主方法，因为它通常需要额外图构造、邻域选择或权重参数，会冲淡 BIC-LR 主线。
   来源：CVPR 2024, https://cvpr.thecvf.com/virtual/2024/poster/30625。

3. Zhao et al., “Multi-view clustering via dynamic unified bipartite graph learning,” Pattern Recognition 2024.
   该文强调动态图过滤和多粒度结构信息，说明锚图结构中的噪声和单一结构刻画确实是近期关注点。对你的启发是：可以把结构项从 G_i = Z_i^T Z_i 改成归一化结构或随机游走式结构，以低成本抑制噪声和尺度差异；不建议引入 learnable graph filter，因为这会增加优化模块和潜在参数。
   来源：Pattern Recognition 156, 2024, DOI: 10.1016/j.patcog.2024.110715。

4. Qin et al., “Discriminative Anchor Learning for Efficient Multi-view Clustering,” accepted by IEEE TMM, arXiv 2024.
   该文指出很多锚点方法忽略了 view-specific anchors 的质量，强调判别性锚点学习与共识锚图协同。对你的启发是：BIC 证据增益作为 view-specific anchor quality 的统计准则有较好的论文定位；对齐模块应尽量服务于已选出的高质量基准视图，而不是再引入复杂加权融合。
   来源：arXiv:2409.16904, DOI: 10.48550/arXiv.2409.16904。

5. Chen et al., “Anchor Learning with Potential Cluster Constraints for Multi-view Clustering,” arXiv 2024.
   该文强调高质量锚点应来自潜在簇结构，而不是散落在簇外。对你的启发是：BIC-LR 的递归分裂停止准则可以从统计模型选择角度解释“何时一个节点足以作为锚点簇”；对齐模块中容量匹配的 balance 约束也可视为避免某些锚点过度吸收匹配的轻量簇覆盖约束。
   来源：arXiv:2412.16519, DOI: 10.48550/arXiv.2412.16519。

6. Zhang et al., “Max-Mahalanobis Anchors Guidance for Multi-View Clustering,” AAAI 2025.
   该文把理想锚点属性概括为 Diversity、Balance、Compactness。对你的启发非常直接：BIC-LR 负责 compactness 与局部模型合理性；minNodeSize 与 BIC 惩罚抑制过碎锚点；矩形容量匹配中的 floor/ceil 自动容量约束对应 alignment 阶段的 balance。建议在论文讨论中引用该文来增强“锚点质量不仅是数量问题，也是覆盖均衡与结构紧凑问题”的论证。
   来源：AAAI 2025, 论文 PDF: https://ojs.aaai.org/index.php/AAAI/article/download/34406/36561。

7. Li et al., “Scalable Unpaired Multi-view Clustering with Bipartite Graph Matching,” Information Fusion 2025.
   该文面向 unpaired multi-view data，提出 bipartite graph matching，并显式讨论 anchor misalignment 和 edge misalignment。虽然你的任务是样本已对齐、锚点未对齐，但它支持一个重要判断：锚点/边结构对齐在最新大规模 MVC 中仍是核心问题。可引用它支持“用二部图匹配或容量匹配修正 P_i 可行域”的必要性；不建议引入 sample-unpaired 模块。
   来源：Information Fusion 116, 2025, DOI: 10.1016/j.inffus.2024.102786。

8. Liu et al., “Anchor-Based Multiview Subspace Clustering With Anchor-wise and Class-wise Alignments,” IEEE TNNLS 2025.
   该文同时做 anchor-wise 与 class-wise alignment，说明“只对齐锚点索引”可能不足，类级结构也可作为辅助约束。对你的启发是：归一化结构矩阵 \hat G_i 可以被看作不显式引入类别变量的轻量 class/cluster structure proxy；不建议现在加入显式 class-wise alignment，因为会新增变量和消融因素。
   来源：IEEE TNNLS 36(11):19733-19747, 2025, DOI: 10.1109/TNNLS.2025.3589264。

9. Lu et al., “Capturing Individuality and Commonality Between Anchor Graphs for Multi-View Clustering,” IJCAI 2025.
   该文认为统一锚图会过度强调共性、忽略视图个性，并提出让 view-specific anchor graphs 与 common anchor graph 实时对齐，同时保持线性复杂度。对你的启发是：你当前保留各视图独立 BIC-LR 锚点，再对齐到 BIC 证据最强的基准视图，是“先保留视图个性，再轻量对齐”的合理路线。该文也支持不要过早加入质量加权融合，而应先修正对齐目标本身。
   来源：IJCAI 2025, DOI: 10.24963/ijcai.2025/652。

10. Fan et al., “Scalable multi-view graph clustering via tensorized consensus and individual anchor graph fusion,” Neurocomputing 2026.
   该文明确指出很多 AMVC 方法要求各视图锚图等大小，忽视数据分布多样性，并采用 adaptive anchor graph fusion 处理不同大小锚图。对你的启发是：m_i != m_b 是合理且必要的设定，因此必须把 P_i 的双边等式置换约束改成数学可行的矩形/容量匹配约束。该文的 tensorized consensus 是重型增强，不建议作为当前主实现。
   来源：Neurocomputing 671, 2026, DOI: 10.1016/j.neucom.2026.132755。

11. Shang et al., “Large-Scale Multiview Clustering via Joint Learning of Anchor Representation and Multigraph Alignment,” IEEE TNNLS 2026.
   该文从 joint learning of anchor representation and multigraph alignment 的角度处理大规模 MVC，说明 anchor representation 与 graph alignment 的耦合仍是最新研究重点。对你的启发是：你的 BIC-LR 先改善 anchor representation，再用 BIC 证据选基准视图，属于更轻量的 staged alternative；后续只需加强对齐模块的约束和归一化，不必改成统一联合优化。
   来源：IEEE TNNLS 37(3):1317-1331, 2026, DOI: 10.1109/TNNLS.2025.3616320。

12. “Fused Partial Gromov-Wasserstein for Structured Objects,” arXiv 2025.
   该文把 FGW 扩展到 partial/unbalanced 场景，用于图匹配、图分类和图聚类。它支持你把当前 feature correspondence + structure correspondence 解释为轻量 FGW-style matching，尤其是不同锚点数时的 partial/rectangular matching 直觉。但它同时引入 mass constraint relaxation、Frank-Wolfe/Sinkhorn 求解等复杂内容，因此仍不建议作为主算法。
   来源：arXiv:2502.09934, DOI: 10.48550/arXiv.2502.09934。

### 10.2 最新文献对本报告优先级的修正

结合 2024-2026 文献后，优先级可以进一步明确：

P0 仍然不变：
- 矩形匹配约束必须修正。2026 年 SMVGC-TA、2025 年 SUMC-BGM 和 IJCAI 2025 anchor graph individuality/commonality 都说明不同大小锚图和锚点对齐是近期核心问题；因此不能继续使用 m_i != m_b 时不可行的双边等式置换约束。
- 对齐后行归一化仍必须保留。近年 bipartite graph / anchor graph 工作都依赖图矩阵的可解释性，若 Z_i P_i 破坏行随机关系，后续谱嵌入的含义会变弱。

P1 建议更强：
- 归一化结构矩阵 \hat G_i 更值得写入主方法。2024 Pattern Recognition 的动态统一二部图和 2025/2026 tensorized anchor graph 工作都强调结构噪声、不同尺度和高阶结构关系。你不宜引入 tensor 或 dynamic filter，但用列归一化 Gram 是低成本吸收这些思想的方式。
- 损失尺度归一化也更值得写入主方法。近年工作大量使用联合目标或多项约束，普遍面临不同项尺度不一致问题。你的归一化版本不增加人工超参数，是最稳妥的处理。

P2 可选方向更清晰：
- lambda_i* 可以作为“减少手动对齐参数搜索”的可选版本，而不是主方法唯一版本。近年工作倾向联合学习，但往往引入更多变量；你的 lambda_i* 是轻量替代，但需要消融证明稳定性。
- class-wise alignment 不建议当前加入主线。TNNLS 2025 AMCA2 说明它有价值，但它会引入类别级变量或伪标签依赖，超出当前 BIC-LR 对齐修正的最小改动边界。

P3 解释方向更有依据：
- FGW-style 解释可以保留，并可补充 Fused Partial GW 2025 作为“不同大小/部分匹配”的理论背景。但仍应明确不引入完整 FGW / Sinkhorn。
- tensorized consensus、deep anchor learning、graph convolution、dynamic filters 都可在 related work 中提及，但不进入主方法。

### 10.3 建议在 markdown 参考文献部分新增的近年文献

建议新增以下 2024-2026 文献，用于强化你的方法定位：

1. Chao Zhang, Xiuyi Jia, Zechao Li, Chunlin Chen, Huaxiong Li. “Learning Cluster-Wise Anchors for Multi-View Clustering.” AAAI 2024. DOI: 10.1609/aaai.v38i15.29609.
2. Suyuan Liu, Ke Liang, Zhibin Dong, Siwei Wang, Xihong Yang, Sihang Zhou, En Zhu, Xinwang Liu. “Learn from View Correlation: An Anchor Enhancement Strategy for Multi-view Clustering.” CVPR 2024.
3. Xingwang Zhao, Shujun Wang, Xiaolin Liu, Jiye Liang. “Multi-view clustering via dynamic unified bipartite graph learning.” Pattern Recognition 156, 2024. DOI: 10.1016/j.patcog.2024.110715.
4. Yalan Qin, Nan Pu, Hanzhou Wu, Nicu Sebe. “Discriminative Anchor Learning for Efficient Multi-view Clustering.” arXiv:2409.16904, 2024; accepted by IEEE TMM.
5. Yawei Chen, Huibing Wang, Jinjia Peng, Yang Wang. “Anchor Learning with Potential Cluster Constraints for Multi-view Clustering.” arXiv:2412.16519, 2024.
6. Pei Zhang, Yuangang Pan, Siwei Wang, Shengju Yu, Huiying Xu, En Zhu, Xinwang Liu, Ivor Tsang. “Max-Mahalanobis Anchors Guidance for Multi-View Clustering.” AAAI 2025.
7. Xingfeng Li, Yuangang Pan, Yuan Sun, Yinghui Sun, Quansen Sun, Zhenwen Ren, Ivor W. Tsang. “Scalable Unpaired Multi-view Clustering with Bipartite Graph Matching.” Information Fusion 116, 2025. DOI: 10.1016/j.inffus.2024.102786.
8. Ye Liu, Hongshan Pu, Junjun Pan, Michael K. Ng, Hongmin Cai. “Anchor-Based Multiview Subspace Clustering With Anchor-wise and Class-wise Alignments.” IEEE TNNLS 36(11), 2025. DOI: 10.1109/TNNLS.2025.3589264.
9. Zhoumin Lu, Yongbo Yu, Linru Ma, Feiping Nie, Rong Wang. “Capturing Individuality and Commonality Between Anchor Graphs for Multi-View Clustering.” IJCAI 2025. DOI: 10.24963/ijcai.2025/652.
10. Lili Fan, Guifu Lu, Ganyi Tang, Ping Zhang, et al. “Scalable multi-view graph clustering via tensorized consensus and individual anchor graph fusion.” Neurocomputing 671, 2026. DOI: 10.1016/j.neucom.2026.132755.
11. Ronghua Shang, Jingya Liu, Xinyuan Wang, Jingyu Zhong, Weitong Zhang, Songhua Xu. “Large-Scale Multiview Clustering via Joint Learning of Anchor Representation and Multigraph Alignment.” IEEE TNNLS 37(3), 2026. DOI: 10.1109/TNNLS.2025.3616320.
12. Yikun Bai et al. “Fused Partial Gromov-Wasserstein for Structured Objects.” arXiv:2502.09934, 2025.

## 参考文献与来源

1. Siwei Wang, Xinwang Liu, Suyuan Liu, Jiaqi Jin, Wenxuan Tu, Xinzhong Zhu, En Zhu. “Align then Fusion: Generalized Large-scale Multi-view Clustering with Anchor Matching Correspondences.” NeurIPS 2022. https://arxiv.org/abs/2205.15075
2. Huimin Ma, Siwei Wang, Shengju Yu, Suyuan Liu, Jun-Jie Huang, Huijun Wu, Xinwang Liu, En Zhu. “Automatic and Aligned Anchor Learning Strategy for Multi-View Clustering.” ACM MM 2024. DOI: 10.1145/3664647.3681273. https://openreview.net/forum?id=TKRqWQVawP
3. Eugene L. Lawler. “The Quadratic Assignment Problem.” Management Science, 1963.
4. Marius Leordeanu, Martial Hebert, Rahul Sukthankar. “An Integer Projected Fixed Point Method for Graph Matching and MAP Inference.” NeurIPS 2009. https://papers.nips.cc/paper/3756-an-integer-projected-fixed-point-method-for-graph-matching-and-map-inference
5. Rainer Burkard, Mauro Dell'Amico, Silvano Martello. “Assignment Problems.” SIAM, 2012. DOI: 10.1137/1.9781611972238. https://epubs.siam.org/doi/10.1137/1.9781611972238
6. David F. Crouse. “On implementing 2D rectangular assignment algorithms.” IEEE Transactions on Aerospace and Electronic Systems, 2016. DOI: 10.1109/TAES.2016.140952.
7. Jianbo Shi, Jitendra Malik. “Normalized Cuts and Image Segmentation.” IEEE TPAMI, 2000. DOI: 10.1109/34.868688.
8. Ulrike von Luxburg. “A Tutorial on Spectral Clustering.” Statistics and Computing, 2007. DOI: 10.1007/s11222-007-9033-z. https://is.mpg.de/ei/publications/4488
9. Titouan Vayer, Laetitia Chapel, Remi Flamary, Romain Tavenard, Nicolas Courty. “Optimal Transport for structured data with application on graphs.” ICML 2019. https://icml.cc/virtual/2019/oral/4404
10. Titouan Vayer, Laetitia Chapel, Remi Flamary, Romain Tavenard, Nicolas Courty. “Fused Gromov-Wasserstein distance for structured objects.” arXiv:1811.02834. https://arxiv.org/abs/1811.02834
11. Marco Cuturi. “Sinkhorn Distances: Lightspeed Computation of Optimal Transport.” NeurIPS 2013. https://papers.nips.cc/paper/4927-sinkhorn-distances-lightspeed-computation-of-optimal-transport
12. David G. Lowe. “Distinctive Image Features from Scale-Invariant Keypoints.” IJCV 2004. DOI: 10.1023/B:VISI.0000029664.99615.94. https://www.cs.ubc.ca/~lowe/papers/ijcv04.pdf
13. Milos Radovanovic, Alexandros Nanopoulos, Mirjana Ivanovic. “Hubs in Space: Popular Nearest Neighbors in High-Dimensional Data.” JMLR 2010. https://jmlr.org/papers/v11/radovanovic10a.html
14. Zhao Chen, Vijay Badrinarayanan, Chen-Yu Lee, Andrew Rabinovich. “GradNorm: Gradient Normalization for Adaptive Loss Balancing in Deep Multitask Networks.” ICML 2018. https://proceedings.mlr.press/v80/chen18a.html
15. Alex Kendall, Yarin Gal, Roberto Cipolla. “Multi-Task Learning Using Uncertainty to Weigh Losses for Scene Geometry and Semantics.” CVPR 2018. https://openaccess.thecvf.com/content_cvpr_2018/html/Kendall_Multi-Task_Learning_Using_CVPR_2018_paper.html
16. S.V.N. Vishwanathan, Nicol N. Schraudolph, Risi Kondor, Karsten M. Borgwardt. “Graph Kernels.” JMLR 2010. https://jmlr.org/papers/v11/vishwanathan10a.html
17. Lawrence Page, Sergey Brin, Rajeev Motwani, Terry Winograd. “The PageRank Citation Ranking: Bringing Order to the Web.” Stanford InfoLab Technical Report, 1999. http://ilpubs.stanford.edu:8090/422/
