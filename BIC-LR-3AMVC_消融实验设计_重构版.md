# BIC-LR-3AMVC 消融实验详细设计（重构版）

更新时间：2026-05-14

本文档是对原版消融设计的系统性重构，主要变更如下：

| 变更点 | 说明 |
|---|---|
| 数据集替换策略 | 明确 VGGFace2 不可用时的替代方案；Caltech256 三视图版本处理方式 |
| 原论文 HBNC 锚点参考数据 | 补充原始 3AMVC 补充材料中各数据集的锚点数与基准视图，作为 B0/A2 的参考基线 |
| 新增 A1b | 单独隔离分裂准则中的 BIC 惩罚项 |
| 新增 A2b | "HBNC 锚点 + BICUnitEvidence 视图选择"，补全对照矩阵 |
| A3 增加视图选择准确性指标 | 记录 BICUnitEvidence 与 SSEMin 的选择一致率 |
| A4 更名并明确语义 | 改为"w/o Multi-View Fusion"，避免与对齐算法有效性混淆 |
| A8 双向触发条件 | 新增"更少锚点但更好性能"方向 |
| 新增 V1 可视化消融 | 参照原论文 Figure 5，对比 HBNC 与 BIC-LR 的锚点分布 |
| 严格消融表限制说明 | 明确 A2 在 fixed_A0_config 下的参数失配风险 |
| 数据集与 B0 搜索预算对齐 | 要求记录 B0 的搜索预算，保证公平比较 |

---

## 1. 数据集说明与问题处理

### 1.1 最终使用数据集

| 数据集 | 样本数 | 类别数 | 视图数 | 来源 | 备注 |
|---|---:|---:|---:|---|---|
| ForestTypes | 523 | 4 | 3 | 原论文 | 小数据集，用于 smoke test 和调试 |
| MFeat | 2000 | 10 | 2 | 原论文 | 快速验证；双视图 |
| Reuters-1200 | 1200 | 6 | 5 | 原论文 | 文本多视图；对 `lambdaBIC` 较敏感 |
| Caltech256-3V | ~30000 | 256 | **3** | 原论文（修改） | 见 §1.2 |
| VGGFace2 / 替代 | — | — | 4 | 原论文（待确认） | 见 §1.3 |

### 1.2 Caltech256 数据集处理

**问题：** 仅找到三视图版本；原始 Caltech256 含第 257 类（clutter）。

**处理方式：**

1. **去除 clutter 类（第 257 类）**：直接按类别标签过滤，保留 256 类数据。
2. **使用三视图版本**：在实验协议中注明 `Caltech256-3V`（三视图），与原论文的 `Caltech256-4V` 区分。
3. **对齐影响分析**：视图数减少使对齐模块的 $P_v$ 矩阵数量从 3 个降为 2 个。由于本文改进主要在锚点生成和视图选择，视图数量差异对主贡献的结论影响有限，但需在论文 §4.1 中注明。
4. **不建议**：不要尝试从原始图像提取第 4 组特征后自行添加为新视图，这会引入和原论文不可比的特征工程差异。

### 1.3 VGGFace2 数据集处理

**问题：** 无法找到预处理后的 .mat 格式数据集。

**处理方式（按优先级排列）：**

**方案 A（优先）：联系作者或下载原始代码仓库附带数据。**
- 论文 GitHub：https://github.com/mahuimin16/3AMVC
- 若仓库中包含 VGGFace2 的预处理特征文件（如 `VGGFace2_feature.mat`），直接使用。
- 若无，向通讯作者 Siwei Wang（swwang.nju@gmail.com）或 Jun-Jie Huang 发送邮件，说明复现需要。

**方案 B：自行提取特征（若方案 A 不可行）。**
- 从 https://github.com/ox-vgg/vgg_face2 下载原始图像。
- 使用和原论文一致的特征提取器（论文未说明具体特征，可通过代码推断）提取 4 组不同类型特征。
- 此方案代价较高，需额外说明特征提取过程。

**方案 C：使用替代大规模人脸数据集。**
- 推荐使用 **MS-Celeb-1M 子集** 或 **YouTube Faces** 多视图特征（常见于多视图聚类基准）。
- 需在论文中注明替换原因。

**方案 D：跳过 VGGFace2，补充 ForestTypes 作为第五个数据集。**
- ForestTypes（523 样本，4 类，3 视图）属于小规模多类场景，可以在主比较表中作为补充行。
- 若最终数据集为 ForestTypes / MFeat / Reuters / Caltech256-3V，则涵盖小、中、大规模三个区间，整体可接受。

**本文推荐：先走方案 A，若一周内未能获取则启用方案 D。**

---

## 2. 原始 3AMVC 锚点参考数据

以下数据来自原始 3AMVC 论文的补充材料，记录了原始 HBNC 在各数据集上为每个视图选出的锚点数，以及被选为基准视图的视图编号。该数据可作为 B0 机制分析表的参考填充值，也是 A2（HBNC Bridge）锚点数预估的参考。

| Dataset | View | HBNC 锚点数 | 是否基准视图 |
|---|---:|---:|---:|
| ForestTypes | 1 | 10 | |
| ForestTypes | 2 | 16 | |
| ForestTypes | **3** | **20** | ✓ |
| MFeat | **1** | **54** | ✓ |
| MFeat | 2 | 64 | |
| Reuters | 1 | 62 | |
| Reuters | 2 | 48 | |
| Reuters | 3 | 45 | |
| Reuters | 4 | 13 | |
| Reuters | **5** | **53** | ✓ |
| Caltech256 | 1 | 48 | |
| Caltech256 | 2 | 67 | |
| Caltech256 | **3** | **62** | ✓ |
| Caltech256 | 4 | 45 | |
| VGGFace2 | 1 | 33 | |
| VGGFace2 | 2 | 74 | |
| VGGFace2 | **3** | **66** | ✓ |
| VGGFace2 | 4 | 38 | |

**关键观察：**

1. 原始 HBNC 基准视图的锚点数并不总是最多的（MFeat：基准视图 1 有 54 个锚点，视图 2 有 64 个；Caltech256：基准视图 3 有 62 个，视图 2 有 67 个），说明原始 SSEMin 准则选出的不是"锚点最多的视图"，而是"样本分布最紧凑的视图"。
2. BIC-LR-3AMVC 的 BICUnitEvidence 是否会选出相同的基准视图，是 A3 的核心机制问题。
3. A2（HBNC Bridge）在这些数据集上的锚点数应与上表接近（具体取决于随机种子）。

---

## 3. 实验目的

BIC-LR 改进包含三个核心设计：

1. 用似然比增益 `2 * (logL1 - logL0)` 判断节点是否值得二分。
2. 在似然比增益上加入 BIC 复杂度惩罚 `lambdaBIC * (d+1) * log(n_C)`，避免锚点过分裂。
3. 用每个视图的单位 BIC 证据增益（BICUnitEvidence）选择基准视图，而不是原始 3AMVC 的 SSE 之和最小准则（SSEMin）。

消融实验需要**分别验证**这三个设计的独立贡献，以及它们协同产生的整体效果。多视图对齐融合不是似然比模块本身的贡献，但决定了 BIC-LR 锚点质量能否传递到最终聚类结果，因此保留为辅助消融。

---

## 4. 当前代码模块对应

| 功能 | 主要文件 | 说明 |
|---|---|---|
| 原始 3AMVC 单视图锚点入口 | `3AMVC-main/Neighbor.m` | B0 和 A2 的基础入口 |
| 原始 HBNC 预划分 | `3AMVC-main/Pre_HBNC.m` | 原始 3AMVC 的初始锚点划分 |
| 原始 HBNC 改进划分 | `3AMVC-main/Impro_HBNC.m` | 原始 3AMVC 的迭代锚点细化 |
| 原始距离阈值判据 | `3AMVC-main/criterion.m` | 原始 HBNC 的启发式切分准则 |
| 完整 BIC-LR 锚点生成 | `3AMVC-main/biclr/BIC_LR_HBNC.m` | 递归二分；记录 accepted/rejected split、锚点大小、证据信息 |
| 单个节点 BIC-LR 切分 | `3AMVC-main/biclr/biclr_best_split.m` | 核心公式：LR 增益减去 BIC 惩罚 |
| 单簇似然 | `3AMVC-main/biclr/biclr_loglik_single.m` | 由节点整体 SSE 估计方差 |
| 双簇似然 | `3AMVC-main/biclr/biclr_loglik_double.m` | 由左右子节点 SSE 估计共享方差 |
| 视图级 BIC 证据 | `3AMVC-main/biclr/biclr_view_evidence.m` | 衡量最终锚点划分相对根节点单簇模型的 BIC 改善 |
| BIC 证据选基准视图 | `3AMVC-main/biclr/biclr_select_target_view.m` | 选择单位 BIC 证据增益最大的视图 |
| 主网格搜索 | `3AMVC-main/run_biclr_grid_search.m` | 完整方法入口 |
| 结果分析 | `3AMVC-main/analysis/biclr_result_tools/analyze_biclr_result_dirs.m` | 可复用结果汇总与敏感度分析 |

---

## 5. 公共实验协议

### 5.1 数据集分工

| 数据集 | 主要用途 | 备注 |
|---|---|---|
| `ForestTypes` | Smoke test、调试、小数据集验证 | 运行速度快 |
| `MFeat` | 双视图验证；与原论文直接可比 | 对 `minNodeSize` 较敏感 |
| `Reuters-1200` | 多视图文本场景；对 `lambdaBIC` 较敏感 | 5 个视图，基准视图选择效果明显 |
| `Caltech256-3V` | 大规模验证；去除 clutter 类（第 257 类） | 注明与原论文 4 视图版本的差异 |

### 5.2 B0 与 A0 定义

| ID | 名称 | 锚点生成 | 目标视图 | 对齐融合 | 作用 | 优先级 |
|---|---|---|---|---|---|---|
| B0 | Original 3AMVC | 原始 HBNC | SSEMin（原始 3AMVC Eq.8） | 原始 3AMVC 对齐融合 | 原论文完整基线 | **必做基线** |
| A0 | Full BIC-LR-3AMVC | BIC-LR | BICUnitEvidence | 当前 3AMVC 对齐融合 | 完整改进方法，所有消融的主要参照 | **必做参照** |

> **B0 搜索预算要求：** B0 的 `beta` 和 `lambda` 必须在与 A0 可比的网格规模下搜索（例如两者均使用 $3\times5$ 或 $4\times4$ 网格）。B0 不使用 `lambdaBIC/minNodeSize`，但需要在结果文件中记录 `numGridConfigs`。若 B0 使用原始推荐参数而不搜索，则在论文中显式说明，并将该数字视为 B0 的下界。

**A0 的活跃超参数：**
```text
beta / lambda / lambdaBIC / minNodeSize
```

### 5.3 评价指标

主文推荐展示：

| 指标 | 说明 |
|---|---|
| ACC | 主指标 |
| NMI | 聚类结构一致性 |
| AR | Adjusted Rand Index（代码中对应 ARI） |

完整结果继续保存：
```text
ACC, NMI, Purity, Fscore, Precision, Recall, AR, Entropy
```

Fscore 和 Purity 放在补充表或附录中。

### 5.4 记录字段

每条结果至少保存以下字段：

| 字段 | 说明 |
|---|---|
| `methodName` | `B0_Original3AMVC`、`A0_Full`、`A1_woBIC` 等 |
| `datasetName` | 数据集名称 |
| `beta` | 对齐/图学习参数 |
| `lambda` | 多视图融合参数；单视图消融记为 `NaN` |
| `lambdaBIC` | BIC 惩罚系数；A1 固定为 `0`，B0/A2 记为 `NaN` |
| `minNodeSize` | BIC-LR 最小叶节点样本数；B0/A2 不适用时记为 `NaN` |
| `tauSplit` | 默认固定为 `0` |
| `targetSelectionMethod` | `BICUnitEvidence` / `LRUnitEvidence` / `SSEMin` / `Original3AMVC` / `TargetOnly` |
| `targetView` | 被选为基准的视图编号 |
| `anchorCounts` | 每个视图的锚点数（数组） |
| `anchorCountsStd` | 多 seed 下每个视图锚点数的标准差 |
| `acceptedSplits` | 每个视图接受的切分数；B0/A2 无法定义时记为 `NaN` |
| `rejectedSplits` | 每个视图拒绝的切分数；B0/A2 无法定义时记为 `NaN` |
| `splitDepthProfile` | 每个深度层接受分裂的比例（数组）；用于 P1 敏感性热力图 |
| `anchorEvidenceGain` | 每个视图的单位 BIC/LR 证据增益（数组） |
| `totalSSEPerView` | 每个视图的总 SSE（数组） |
| `meanLeafSize` | 平均叶节点样本数 |
| `maxDepth` | 最大树深度 |
| `metricsMean` | 聚类指标均值（结构体） |
| `metricsStd` | 聚类指标标准差（结构体） |
| `totalTime` | 总耗时 |
| `anchorTime` | 锚点生成耗时 |
| `alignmentTime` | 对齐融合耗时；A4 可为 `0` 或单视图耗时 |
| `randomSeed` | 随机种子 |
| `numGridConfigs` | 当前方法实际搜索的参数组合数 |
| `searchBudget` | 搜索预算描述，例如 `numGridConfigs × numSeeds × numRuns` |
| `selectedConfig` | 最终选择的参数组合 |
| `selectionMetric` | 用于选择最优配置的指标，如 `ACC` |
| `selectionRule` | 如 `best_mean_ACC_then_NMI`、`fixed_A0_config` |

### 5.5 结果口径

| 口径 | 设置 | 用途 |
|---|---|---|
| **主性能比较** | 每个方法在相同评价协议和可比搜索预算下选择最优配置 | 展示每个变体可达到的最好性能 |
| **严格消融比较** | 固定 A0 的 `selectedConfig`，只替换被消融的模块 | 隔离单个组件本身的贡献 |

> **严格消融的局限性（必须在论文中注明）：** 对于 A2（HBNC Bridge），固定 A0 的 `beta/lambda` 参数时，由于 HBNC 和 BIC-LR 产生的锚点数可能不同，这些参数在 A2 上未必是最优的。因此严格消融下的 A0 vs A2 只能部分隔离锚点生成的贡献；主性能表（各方法自选最优）对 A2 的评估更为公平。对 A1，固定 A0 的所有参数后将 `lambdaBIC` 置为 `0`，此比较是严格有效的。

### 5.6 推荐输出目录

```text
3AMVC-main/ablation_biclr/
  configs/
  cache/
  res/
  reports/
  run_ablation_biclr_suite.m
  run_one_biclr_ablation.m
```

---

## 6. 实验总览

### 6.1 核心基线与消融

| ID | 名称 | 锚点生成 | 目标视图选择 | 对齐融合 | 作用 | 优先级 |
|---|---|---|---|---|---|---|
| B0 | Original 3AMVC | 原始 HBNC | SSEMin（原始） | 原始 3AMVC | 原论文完整基线 | **必做** |
| A0 | Full BIC-LR-3AMVC | BIC-LR | BICUnitEvidence | 当前 3AMVC | 完整改进方法 | **必做** |
| A1 | w/o BIC（联合去除） | LR only（`lambdaBIC=0`） | LRUnitEvidence | 与 A0 相同 | 验证 BIC 惩罚的**联合**贡献 | **必做** |
| A1b | w/o BIC in split only | LR only（`lambdaBIC=0`） | BICUnitEvidence（固定） | 与 A0 相同 | 单独隔离分裂准则中的 BIC 惩罚 | **建议做** |
| A2 | w/o LR / HBNC Bridge | 原始 HBNC | SSEMin | 与 A0 相同 | 验证 BIC-LR 锚点生成 | **必做** |
| A2b | HBNC + BIC View | 原始 HBNC | BICUnitEvidence（代理） | 与 A0 相同 | 隔离 BICUnitEvidence 对视图选择的贡献 | **建议做** |
| A3 | w/o BIC-view-selection | BIC-LR | SSEMin | 与 A0 相同 | 验证 BICUnitEvidence 视图选择 | **必做** |
| A4 | w/o Multi-View Fusion | BIC-LR | BICUnitEvidence | **关闭，仅用目标视图** | 验证多视图融合是否必要 | 建议做 |

> **A1 双重效应说明：** A1 同时去掉了 BIC 惩罚在**分裂准则**和**视图质量评分**中的作用，因此 A0 vs A1 验证的是两个 BIC 项的**联合**贡献。A1b 的作用是单独隔离分裂准则中的 BIC 惩罚：A1b 中 `lambdaBIC=0` 仅影响分裂判断，视图质量评分仍使用原始 A0 的 BIC 证据。由于 A0 和 A1b 在分裂阶段使用不同 `lambdaBIC`，A1b 的 `anchorEvidenceGain` 是用 LR 增益归一化（无惩罚）计算的，但选择规则一致，命名为 `BICStyleEvidence_NoSplitPenalty`。

### 6.2 对照矩阵（锚点生成 × 视图选择）

|  | BIC-LR 锚点 | HBNC 锚点 |
|---|---|---|
| **BICUnitEvidence** | **A0**（完整方法） | **A2b**（新增） |
| **SSEMin** | **A3** | **A2 ≈ B0** |

> A2b 补全了左下角空缺，使对照矩阵完整，可以独立回答"即使不改变锚点生成，BICUnitEvidence 视图选择能否单独带来收益"这一问题。

### 6.3 敏感性与稳定性

| 原编号 | 推荐名称 | 类型 | 说明 |
|---|---|---|---|
| A5 | P1 `lambdaBIC` sensitivity | 参数敏感性 | 分析 BIC 惩罚强度对性能、锚点数、分裂数的影响 |
| A6 | P2 `minNodeSize` sensitivity | 参数敏感性 | 分析最小节点大小对锚点粒度和聚类性能的影响 |
| A7 | S1 seed stability | 稳定性分析 | 多随机种子重复实验 |

### 6.4 可视化消融

| ID | 名称 | 说明 |
|---|---|---|
| V1 | Anchor Distribution Visualization | HBNC vs BIC-LR vs A1（过分裂）锚点分布对比 |

### 6.5 条件性补充

| ID | 名称 | 触发条件 | 作用 |
|---|---|---|---|
| A8 | Matched Anchor Number Control | 见 §14 | 排除"锚点数量差异"的混淆解释 |

---

## 7. A1：w/o BIC（联合去除）

### 7.1 要回答的问题

去掉 BIC 复杂度惩罚后（同时影响分裂准则和视图质量评分），锚点是否过分裂？最终聚类性能是否下降？

> **注意：** A1 验证的是 BIC 惩罚两处使用的**联合**贡献，不是单独隔离分裂准则中的惩罚。单独隔离请见 A1b（§8）。

### 7.2 具体设置

| 项目 | 设置 |
|---|---|
| 分裂增益 | 保留 `2 * (logL1 - logL0)` |
| BIC 惩罚 | 去掉，即 `lambdaBIC = 0` |
| `minNodeSize` | 保留，与 A0 一致 |
| `tauSplit` | 固定为 `0` |
| 目标视图质量命名 | `LRUnitEvidence`（不再是 BIC evidence） |
| 多视图对齐 | 保持 A0 不变 |
| 记录名 | `A1_woBIC_Joint` |

> **代码注意：** 确认 `biclr_view_evidence` 在 `lambdaBIC=0` 时自动退化为 LR evidence，而不是静默使用上次存储的 BIC 值。对应结果字段必须写 `LRUnitEvidence`，不得写 `BICUnitEvidence`。

### 7.3 参数搜索

| 参数 | 搜索方式 |
|---|---|
| `lambdaBIC` | 固定 `0` |
| `minNodeSize` | 与 A0 相同或相邻的搜索范围 |
| `beta` | 与 A0 相同 |
| `lambda` | 与 A0 相同 |

### 7.4 需要记录的机制指标

| 指标 | 解释 |
|---|---|
| `anchorCounts` | 检查是否明显多于 A0 |
| `acceptedSplits` | 检查接受分裂数是否暴涨 |
| `splitDepthProfile` | 检查深层节点是否持续接受分裂（过分裂的典型模式） |
| `meanLeafSize` | 检查叶节点是否过小 |
| `totalSSEPerView` | 检查训练误差是否下降但聚类指标未改善 |
| `ACC/NMI/AR` | 判断聚类性能是否下降 |

### 7.5 预期结果和解释

| 现象 | 解释 |
|---|---|
| 锚点数增加但 ACC/NMI/AR 下降 | 过分裂，锚点代表性变差 |
| SSE 降低但聚类指标下降 | 仅优化局部拟合，不利于全局聚类 |
| 小数据集下降更明显 | 小样本节点更容易被过拟合切分 |
| A1 与 A0 持平 | BIC 惩罚主要提供稳定性和锚点数量控制，而非大幅提升精度 |

---

## 8. A1b：w/o BIC in Split Criterion Only（可选，建议做）

### 8.1 要回答的问题

单独去掉分裂准则中的 BIC 惩罚（保留视图质量评分中的 BIC 风格），锚点是否过分裂？

### 8.2 具体设置

| 项目 | 设置 |
|---|---|
| 分裂增益 | 纯 LR，即 `lambdaBIC_split = 0` |
| 目标视图质量 | 用与 A0 相同的 BIC 风格（按 LR 增益归一化但不扣 BIC 惩罚），命名为 `BICStyleEvidence_NoSplitPenalty` |
| `minNodeSize` | 与 A0 一致 |
| 多视图对齐 | 保持 A0 不变 |
| 记录名 | `A1b_woBICSplit` |

### 8.3 与 A1 的对比关系

| 变体 | 分裂 BIC 惩罚 | 视图 BIC 评分 | 说明 |
|---|---|---|---|
| A0 | ✓ | ✓ | 完整方法 |
| A1 | ✗ | ✗（退化为 LR） | 联合去除 |
| A1b | ✗ | ✓（BIC 风格） | 单独隔离分裂惩罚 |

通过 A0 vs A1b vs A1 三路对比，可以判断：

- A0 vs A1b：分裂准则中的 BIC 惩罚的独立贡献；
- A1b vs A1：视图评分中的 BIC 风格的独立贡献。

---

## 9. A2：w/o LR / HBNC Bridge

### 9.1 要回答的问题

在相同后续目标视图桥接规则和对齐融合管线下，BIC-LR 锚点生成是否优于原始 3AMVC 的 HBNC 启发式锚点生成？

### 9.2 为什么不把裸 DeltaSSE 作为主 A2

1. 裸 `DeltaSSE > 0` 不是原始 3AMVC 的锚点选择方法，审稿人可能认为这是人为构造的弱基线。
2. 裸 SSE 增益与节点样本数、维度、数据尺度强相关，若不归一化，比较不严谨。

主 A2 固定为 `A2_woLR_OriginalHBNC_Bridge`，不再使用原始 3AMVC 的完整目标视图与融合路径，以避免与 B0 重复。

### 9.3 具体设置

| 项目 | 设置 |
|---|---|
| 锚点生成 | 原始 3AMVC 的 `Neighbor → Pre_HBNC → Impro_HBNC` |
| 似然函数 | 不使用 |
| BIC 惩罚 | 不使用 |
| 目标视图 | `SSEMin`，即总 SSE 最小的视图（与原始 3AMVC Eq.8 一致） |
| 多视图对齐 | 与 A0 相同的当前对齐融合管线 |
| 记录名 | `A2_woLR_OriginalHBNC_Bridge` |

> **参考锚点数：** 参见 §2 的原论文补充材料数据，A2 在各数据集上的锚点数应接近该表格中的值（允许随机种子波动）。

### 9.4 后续实现方式

```matlab
% 复用原始 HBNC，不重写
[res_neighbor, time_neighbor, label_neighbor, object, theta, class] = Neighbor(Xv, Y, options);

% 固定使用 SSEMin 选择目标视图
totalSSE = cellfun(@sum, objectAll);
[~, targetView] = min(totalSSE);

% 随后进入与 A0 相同的 algo_qp 对齐融合流程
```

### 9.5 需要记录的额外字段

| 字段 | 说明 |
|---|---|
| `anchorCounts` | 对比是否接近 §2 中的参考值 |
| `anchorCountsStd` | 多 seed 下锚点数的标准差（HBNC 有随机性） |
| `targetView` | 与 A0 的基准视图是否一致 |

### 9.6 主要比较关系

| 比较 | 目的 |
|---|---|
| A0 vs A2 | BIC-LR 锚点相对原始 HBNC 锚点的贡献（主消融） |
| A3 vs A2 | 在视图选择均退化为 SSEMin 时，BIC-LR 锚点 vs HBNC 锚点 |
| A0 vs B0 | 完整方法相对原论文的整体提升 |

---

## 10. A2b：HBNC Anchor + BIC View Selection（建议做）

### 10.1 要回答的问题

即使不改变锚点生成，BICUnitEvidence 视图选择能否单独带来收益？

### 10.2 为什么需要 A2b

A2b 填补了对照矩阵中"HBNC 锚点 + BIC 视图"格的空缺。若 A2b 优于 A2，说明 BICUnitEvidence 即使搭配 HBNC 锚点也有效；若持平，说明 BICUnitEvidence 的收益依赖于 BIC-LR 锚点的质量特性。

### 10.3 具体设置

| 项目 | 设置 |
|---|---|
| 锚点生成 | 原始 HBNC（与 A2 完全相同） |
| 目标视图选择 | BICUnitEvidence 代理：$\text{EvidenceProxy}^{(v)} = (W_0^{(v)} - W_T^{(v)}) / (m_v \cdot \log n)$ |
| 多视图对齐 | 与 A0 相同 |
| 记录名 | `A2b_HBNC_BICViewSelect` |

**BICUnitEvidence 代理实现说明：** 对于 HBNC 产生的锚点集合，无法直接获取逐层分裂的 LR 历史，因此采用如下代理：

$$\text{EvidenceProxy}^{(v)} = \frac{W_0^{(v)} - W_T^{(v)}}{m_v \cdot \log n}$$

其中 $W_0^{(v)}$ 为视图 $v$ 全样本绕均值的总 SSE（单簇基准），$W_T^{(v)}$ 为 HBNC 最终锚点划分的总 SSE，$m_v$ 为锚点数，$n$ 为样本数。分母 $m_v \cdot \log n$ 对应 BIC 惩罚的参数代价项，使不同锚点数的视图可以横向比较。

### 10.4 与其他变体的比较

| 变体 | 锚点 | 视图选择 |
|---|---|---|
| A2 | HBNC | SSEMin |
| A2b | HBNC | BICUnitEvidence（代理） |
| A3 | BIC-LR | SSEMin |
| A0 | BIC-LR | BICUnitEvidence |

A2b vs A2 单独测试视图选择的贡献；A3 vs A2 单独测试锚点生成的贡献（两者均使用 SSEMin 视图选择）。

---

## 11. A3：w/o BIC-view-selection / SSE Target

### 11.1 要回答的问题

BIC 证据选择目标视图是否有效，还是用 SSEMin 也可以？

### 11.2 具体设置

| 项目 | 设置 |
|---|---|
| 锚点生成 | 完全使用 A0 的 BIC-LR |
| 分裂准则 | 完全使用 A0 |
| BIC 惩罚 | 完全使用 A0 |
| **唯一改动** | `targetView = argmin_v sum(totalSSE(v))` |
| 多视图对齐 | 保持 A0 不变 |
| 记录名 | `A3_SSETarget` |

> **SSEMin 定义对齐：** SSEMin 即原始 3AMVC 的 Eq.(8) 准则——选择各簇内平方误差之和最小的视图。A3 和 B0、A2 在视图选择规则上应使用**完全相同的实现**，避免引入额外差异。

> A3 可与 A0 共用锚点缓存，只需将 `targetSelectionMethod` 切换为 `SSEMin`。结果文件名必须不同。

### 11.3 视图选择准确性机制分析（新增）

A3 是专门针对视图选择模块的消融，需要额外记录以下字段，以回答"哪个方法选出了更好的视图"：

| 字段 | 说明 |
|---|---|
| `bicTargetView` | A0 的 BICUnitEvidence 规则选出的视图编号 |
| `sseTargetView` | A3 的 SSEMin 规则选出的视图编号 |
| `targetViewAgreement` | 两者是否一致（Boolean，跨 seed 统计一致率） |
| `bicEvidencePerView` | 每个视图的 BIC 证据增益（数组） |
| `totalSSEPerView` | 每个视图的总 SSE（数组） |
| `sseRankCorrelation` | BICUnitEvidence 排序与 SSEMin 排序的 Kendall τ |

**后续分析建议：**

1. 统计每个数据集上 BICUnitEvidence 和 SSEMin 选出不同视图的比例（`1 - targetViewAgreement`）。
2. 若两者频繁选出不同视图，则对比"被选中视图的单视图 ACC"以验证 BICUnitEvidence 选择的视图是否更优。
3. 参照 §2 中的原论文补充材料数据（B0 的基准视图），判断 A0 和 A3 是否与 B0 保持一致或有所不同。

### 11.4 预期结果和解释

- 若 A3 低于 A0 且两者经常选出不同视图：BICUnitEvidence 有效，且视图差异是性能差异的机制来源。
- 若 A3 与 A0 持平：视图选择不是主要性能来源，但 BICUnitEvidence 提供了与 BIC-LR 框架一致的无参数选择规则。

---

## 12. A4：w/o Multi-View Fusion（单视图基线）

### 12.1 语义说明（重要）

**A4 去掉多视图对齐融合后，由于各视图锚点数不同，无法直接对未对齐锚图取平均，因此 A4 必然退化为单视图基线（只使用目标视图的锚图）。**

因此，A0 vs A4 回答的问题是：**多视图融合是否必要**，而非"对齐算法本身是否有效"。若要单独测试对齐算法的有效性，需要将所有视图锚点数固定相同（会引入其他变量），本实验不推荐这样做。

A4 正确命名为 `w/o Multi-View Fusion (Single-View Baseline)`，论文中需说明此限制。

### 12.2 具体设置

| 项目 | 设置 |
|---|---|
| 锚点生成 | 使用完整 BIC-LR |
| 目标视图 | 使用 A0 的 BICUnitEvidence |
| 对齐融合 | **关闭** |
| 最终聚类 | 只使用目标视图的单视图锚图 |
| `lambda` | 不适用，记为 `NaN` |
| 记录名 | `A4_woMultiViewFusion` |

### 12.3 实现说明

不要做"未对齐锚图直接平均"。推荐实现单视图版本：

```matlab
% 只取目标视图
Xb = X{targetView};
Theta_b = thetaall{targetView};
% 调用单视图 QP 求解器
Z_b = algo_qp_single_view(Xb, Y, Theta_b, beta);
```

---

## 13. A5/P1：lambdaBIC 敏感性

### 13.1 要回答的问题

完整方法对 BIC 惩罚强度是否敏感？`lambdaBIC` 是否存在合理有效区间，而不是只在单点偶然有效？

### 13.2 具体设置

主文敏感性曲线只改变 `lambdaBIC`，固定 A0 的其他 `selectedConfig` 参数：

```text
lambdaBIC varies; beta, lambda, minNodeSize fixed to A0 selectedConfig.
```

### 13.3 推荐取值

| 数据集 | 推荐 `lambdaBIC` 范围 |
|---|---|
| `ForestTypes` | `[0, 0.25, 0.5, 0.75, 1, 1.5, 2, 3]` |
| `MFeat` | `[0, 0.5, 0.75, 1, 1.5, 2, 3]` |
| `Reuters-1200` | `[0, 0.1, 0.22, 0.35, 0.5, 0.75, 1]` |
| `Caltech256-3V` | `[0.5, 1, 1.5, 2, 2.5, 3, 4]` |

> **smoke test 建议：** 先在 ForestTypes 上跑极端值（`lambdaBIC=0` 和 `lambdaBIC=100`），确认前者过分裂、后者只产生 1 个锚点，再缩小范围做完整扫描。

### 13.4 需要画的图

| 横轴 | 纵轴 |
|---|---|
| `lambdaBIC` | ACC / NMI / AR |
| `lambdaBIC` | 总锚点数 |
| `lambdaBIC` | 平均 `acceptedSplits` |
| `lambdaBIC`（热力图） | 各深度层的分裂接受率（`splitDepthProfile`） |

### 13.5 预期结果

| `lambdaBIC` 区间 | 预期行为 |
|---|---|
| 太小（→0） | 锚点过多，容易过分裂（退化为 A1） |
| 中等 | 锚点数和聚类指标达到较好平衡 |
| 太大 | 锚点过少，欠划分，局部结构表达不足 |

---

## 14. A6/P2：minNodeSize 敏感性

### 14.1 要回答的问题

最小节点大小如何影响锚点粒度、锚点数量和最终聚类结果？

### 14.2 具体设置

主文只改变 `minNodeSize`，固定 A0 的其他参数：

```text
minNodeSize varies; beta, lambda, lambdaBIC fixed to A0 selectedConfig.
```

### 14.3 推荐取值

| 数据集 | 推荐 `minNodeSize` 范围 |
|---|---|
| `ForestTypes` | `[5, 10, 15, 20, 30]` |
| `MFeat` | `[20, 30, 40, 50, 60]` |
| `Reuters-1200` | `[8, 12, 16, 22, 32]` |
| `Caltech256-3V` | `[40, 60, 80, 120, 160]` |

### 14.4 需要记录的机制指标

| 指标 | 作用 |
|---|---|
| `anchorCounts` | 观察锚点数随 `minNodeSize` 增大而下降 |
| `meanLeafSize` | 判断叶节点规模是否合理 |
| `maxDepth` | 观察树是否过深 |
| `acceptedSplits/rejectedSplits` | 观察分裂是否被节点大小限制截断 |
| `ACC/NMI/AR` | 判断最佳粒度 |

---

## 15. A7/S1：随机种子稳定性与统计检验

### 15.1 要回答的问题

改进带来的收益是否稳定，而不是来自单次随机初始化？

### 15.2 具体设置

| 项目 | 设置 |
|---|---|
| 方法 | 至少运行 B0、A0、A1、A2、A3；预算允许时加入 A4、A1b、A2b |
| 数据集 | 四个主数据集 |
| 参数 | 每个方法使用其对应最优参数 |
| 种子 | 预实验：`[1,2,3,4,5]`；论文最终：`[1:10]` |
| 评价次数 | 每个 seed 内保留当前 `numRuns` 聚类重复 |

### 15.3 每个 seed 应控制的随机源

1. BIC-LR 锚点生成中的 `randomSeed`；
2. 原始 HBNC 中 `Pre_HBNC` 和 `Impro_HBNC` 的随机目标样本选择（B0、A2）；
3. 谱嵌入或 k-means 聚类评价中的随机初始化；
4. 缓存键中的 `seed` 字段。

### 15.4 结果表

| Dataset | Method | ACC mean | ACC std | NMI mean | NMI std | AR mean | AR std | Avg anchors |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| MFeat | B0 Original | | | | | | | |
| MFeat | A0 Full | | | | | | | |
| MFeat | A1 w/o BIC | | | | | | | |
| MFeat | A2 HBNC Bridge | | | | | | | |
| MFeat | A3 SSE Target | | | | | | | |

### 15.5 推荐统计报告

| 情况 | 推荐做法 |
|---|---|
| 单数据集内多 seed | 报告 mean±std、胜负次数；paired test 只作为补充 |
| 多数据集整体比较 | 报告平均排名和胜负情况；Friedman test 作为补充 |
| 数据集数量较少 | 避免强行使用"显著优于" |
| 若要强调显著性 | 至少使用 10 seeds，报告 p-value 和校正方式 |

推荐补充统计表：

| Dataset | Comparison | Win/Tie/Loss | Mean Diff. ACC | Mean Diff. NMI | Mean Diff. AR | Test |
|---|---|---:|---:|---:|---:|---|
| All | A0 vs A1 | | | | | Wilcoxon, supplementary |
| All | A0 vs A2 | | | | | Wilcoxon, supplementary |
| All | A0 vs A3 | | | | | Wilcoxon, supplementary |

---

## 16. A8：Matched Anchor Number Control（条件性补充）

### 16.1 触发条件（双向）

**触发方向 A（更多锚点）：** A0 平均锚点数明显多于 B0 或 A2，同时 A0 性能也更好：

```text
Trigger A8-More if avgAnchors(A0) / avgAnchors(B0) > 1.3
or avgAnchors(A0) / avgAnchors(A2) > 1.3,
AND A0 achieves clearly better ACC/NMI/AR.
```

此时需要排除"更多锚点导致性能更好"的混淆解释。

**触发方向 B（更少锚点，无需 A8）：** A0 平均锚点数明显**少于** B0 或 A2，同时 A0 性能更好：

```text
No A8 needed if avgAnchors(A0) / avgAnchors(B0) < 0.85
AND A0 achieves better ACC/NMI/AR.
```

这是更有力的结果，直接在机制分析表中报告：BIC-LR 用**更少的锚点**实现了**更好的聚类性能**，说明锚点质量而非数量是性能来源。

**触发判断表：**

| Dataset | Avg anchors A0 | Avg anchors B0 | Ratio A0/B0 | Avg anchors A2 | Ratio A0/A2 | Direction | Trigger A8? |
|---|---:|---:|---:|---:|---:|---|---|
| ForestTypes | | | | | | | |
| MFeat | | | | | | | |
| Reuters-1200 | | | | | | | |
| Caltech256-3V | | | | | | | |

### 16.2 要回答的问题

性能提升是否只是因为 A0 使用了更多锚点？

### 16.3 可选实现方式

| 方式 | 说明 | 风险 |
|---|---|---|
| 固定锚点数 K-means anchors | 每个视图固定为 A0 对应视图的锚点数 | 引入 K-means 随机性和新基线 |
| 调整 HBNC 停止参数 | 使原始 HBNC 锚点数接近 A0 | 需要额外停止阈值 |

A8 是条件性补充实验，若实现需新增两个以上超参数，应放弃或只做定性分析。

---

## 17. V1：锚点分布可视化消融

### 17.1 目的

参照原论文 Figure 5（K-means vs HBNC 锚点对比），为 BIC-LR 改进提供直观验证。

### 17.2 建议对比内容

在 MFeat 第一视图（原论文 Figure 5 使用的数据）上并排展示三组锚点：

| 子图 | 内容 |
|---|---|
| (a) 原始 HBNC 选出的锚点 | 参照原论文 Figure 5(b)，对应 A2/B0 |
| (b) BIC-LR（A0 最优 `lambdaBIC`）选出的锚点 | 完整改进方法 |
| (c) LR only（`lambdaBIC=0`，A1）选出的锚点 | 展示过分裂效果 |

**期望效果：** 子图 (b) 的锚点分布比 (a) 更均匀紧凑；子图 (c) 的锚点过多，覆盖局部噪声点。

### 17.3 实现说明

- 使用与论文一致的降维方式（如 t-SNE 或 PCA）将样本和锚点投影到 2D。
- 样本点用小点表示，锚点用红星标出（与原论文一致）。
- 三张图使用相同的随机种子和降维参数，保证可比性。

---

## 18. 推荐运行顺序

| 顺序 | 实验 | 原因 |
|---:|---|---|
| 1 | B0 on `ForestTypes` | 先确认原始基线可复现 |
| 2 | A0 on `ForestTypes` | 确认完整方法入口正常 |
| 3 | 极端 `lambdaBIC` smoke test | 确认取值范围合理（所有节点接受 vs 全部拒绝） |
| 4 | A3 on `ForestTypes` | 只改变目标视图，最容易验证缓存复用 |
| 5 | A1 on `ForestTypes` | 设置 `lambdaBIC=0`，快速检查过分裂 |
| 6 | A2 on `ForestTypes` | 验证 HBNC Bridge 流程；对比 §2 中的参考锚点数 |
| 7 | A4 on `ForestTypes` | 验证单视图流程 |
| 8 | B0/A0/A1/A2/A3/A4 全数据集粗搜 | 得到主消融表（主性能口径） |
| 9 | A1b/A2b on 全数据集 | 补全对照矩阵 |
| 10 | 严格消融表：固定 A0 config 重跑 A1/A2/A3/A4 | 得到严格消融口径 |
| 11 | P1/P2 敏感性分析 | 用主结果确定中心参数范围后扫描 |
| 12 | S1 多 seed 稳定性 | 对最终配置做 mean±std |
| 13 | V1 可视化消融 on MFeat | 对比 HBNC / BIC-LR / 过分裂三种锚点 |
| 14 | A8（条件性） | 仅当触发判断表中条件满足时补做 |

---

## 19. 结果表模板

### 19.1 主性能表（每个方法自选最优配置）

| Dataset | B0 Original | A0 Full | A1 w/o BIC | A1b Split only | A2 HBNC Bridge | A2b HBNC+BICView | A3 SSE Target | A4 Single View |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| ForestTypes | | | | | | | | |
| MFeat | | | | | | | | |
| Reuters-1200 | | | | | | | | |
| Caltech256-3V | | | | | | | | |

每格填写：`ACC / NMI / AR`

### 19.2 严格消融表（固定 A0 的 selectedConfig）

| Dataset | A0 fixed | A1 fixed | A2 fixed | A3 fixed | A4 fixed |
|---|---:|---:|---:|---:|---:|
| ForestTypes | | | | | |
| MFeat | | | | | |
| Reuters-1200 | | | | | |
| Caltech256-3V | | | | | |

> **脚注（必须在论文中保留）：** 对 A2，`beta` 和 `lambda` 固定与 A0 一致，但由于 HBNC 和 BIC-LR 产生的锚点数可能不同，这些参数在 A2 上未必是最优配置，此比较只能部分隔离锚点生成模块的贡献。对 A4，`lambda = N/A`（关闭了多视图融合）。

### 19.3 搜索预算表

| Dataset | Method | numGridConfigs | numSeeds | numRuns | searchBudget | selectionRule | selectedConfig |
|---|---|---:|---:|---:|---|---|---|
| MFeat | B0 | | | | | | |
| MFeat | A0 | | | | | | |
| MFeat | A1 | | | | | | |
| MFeat | A2 | | | | | | |
| MFeat | A3 | | | | | | |

### 19.4 机制分析表

| Dataset | Method | Avg anchors | Anchor counts / view | Target view | Accepted splits | Rejected splits | Anchor time | Total time |
|---|---|---:|---|---:|---:|---:|---:|---:|
| MFeat | B0 | | | | N/A | N/A | | |
| MFeat | A0 | | | | | | | |
| MFeat | A1 | | | | | | | |
| MFeat | A2 | | | | N/A | N/A | | |
| MFeat | A3 | | | | | | | |

> 括号内可填入 §2 中的原论文参考值，用于验证 B0 的复现是否正确。

### 19.5 视图选择分析表（A3 专用）

| Dataset | BIC Target View | SSE Target View | Agreement | BIC Evidence per View | SSE per View | Kendall τ |
|---|---:|---:|---:|---|---|---:|
| ForestTypes | | | | | | |
| MFeat | | | | | | |
| Reuters-1200 | | | | | | |
| Caltech256-3V | | | | | | |

### 19.6 参数敏感性图

| 图 | 固定参数 | 变化参数 | 纵轴 |
|---|---|---|---|
| P1-performance | A0 selected `beta/lambda/minNodeSize` | `lambdaBIC` | ACC/NMI/AR |
| P1-complexity | A0 selected `beta/lambda/minNodeSize` | `lambdaBIC` | total anchors / accepted splits |
| P1-depth | A0 selected `beta/lambda/minNodeSize` | `lambdaBIC` | splitDepthProfile 热力图 |
| P2-performance | A0 selected `beta/lambda/lambdaBIC` | `minNodeSize` | ACC/NMI/AR |
| P2-complexity | A0 selected `beta/lambda/lambdaBIC` | `minNodeSize` | total anchors / max depth |

---

## 20. 不建议做的实验

| 实验 | 不建议原因 |
|---|---|
| 去掉 `epsVar` | 数值稳定项，不是方法贡献；去掉可能只产生数值错误 |
| 扫 `maxAnchors` | 保护性上限，容易和过分裂问题混淆 |
| 未对齐锚图直接平均 | 不同视图锚点数量和顺序不对应，比较不成立 |
| 裸 `DeltaSSE > 0` 作为主 A2 | 不是原始 3AMVC，也缺少尺度归一化 |
| 同时改多个组件 | 无法判断性能变化来自哪个组件 |
| 软匹配/矩形 P 矩阵对齐 | 当前目标是不改变对齐模型，且之前效果不好 |
| 对 Caltech256 强行补充第 4 个视图特征 | 引入不可与原论文比较的特征工程差异 |

---

## 21. 后续写代码检查清单

1. 每个消融只改变文档中指定的部分，其余路径严格复用。
2. B0 和 A2 尽量复用 `Neighbor.m`、`Pre_HBNC.m`、`Impro_HBNC.m`、`criterion.m`。
3. 缓存键包含 `dataset/preprocess/view/method/lambdaBIC/minNodeSize/tauSplit/epsVar/randomSeed`。
4. A3 复用 A0 锚点缓存，但结果文件名必须不同。
5. A1 的目标视图质量字段不要写成 `BICUnitEvidence`，应写 `LRUnitEvidence`。
6. A1b 的视图质量字段写为 `BICStyleEvidence_NoSplitPenalty`。
7. A2 缺少 BIC evidence 时，不要强行调用 `biclr_select_target_view`。
8. A2b 调用 `biclr_view_evidence` 的代理版本，基于 HBNC 的 $W_0, W_T, m_v$ 计算证据代理。
9. 所有结果结构体字段一致，便于统一汇总。
10. 每个消融先在 `ForestTypes` 跑一个小网格 smoke test；验证 B0 的锚点数与 §2 的参考数接近。
11. P1 smoke test：先跑 `lambdaBIC=0` 和 `lambdaBIC=100` 两个极端，确认取值范围合理。
12. 主性能表记录各方法在可比搜索预算下的最优配置。
13. 严格消融表固定 A0 的 `selectedConfig`，并在论文脚注中注明 A2 的参数失配风险。
14. 机制分析同时报告性能和锚点数，以及是否与 §2 的原论文参考值一致。
15. V1 可视化消融使用相同的随机种子和降维参数，保证三图可比。
16. A4 结果文件名包含 `SingleView` 字样，论文中命名 `w/o Multi-View Fusion`。

---

## 22. 论文表述建议

推荐按以下逻辑组织实验章节：

1. **B0 vs A0**：说明完整 BIC-LR-3AMVC 相对原始 3AMVC 的整体有效性（主性能表）。
2. **A0 vs A1**：说明 BIC 惩罚（联合）是否抑制过分裂，通过机制指标（锚点数、acceptedSplits）辅助解释。
3. **A0 vs A1b vs A1**（若做）：细化分裂准则和视图评分中 BIC 惩罚各自的独立贡献。
4. **A0 vs A2**：在相同后续对齐融合管线下，说明 BIC-LR 锚点生成是否优于原始 HBNC。
5. **A3 视图选择分析**：A0 vs A3 说明 BICUnitEvidence 视图选择是否有效；配合 §19.5 的视图选择一致率提供机制证据。
6. **A2b vs A2**（若做）：单独说明 BICUnitEvidence 对视图选择的贡献是否依赖 BIC-LR 锚点。
7. **A0 vs A4**：说明多视图融合是否是 BIC-LR 锚点收益传递到最终聚类的必要环节。
8. **V1 可视化**：直观展示 BIC-LR 与 HBNC 锚点分布的差异，以及过分裂的视觉效果。
9. **P1/P2 敏感性**：说明关键参数存在稳定有效区间（不是只在单点有效）。
10. **S1 稳定性**：说明结果不是单次随机性造成，统计检验作为补充证据。
11. **A8（条件性）**：若触发，排除"更多锚点"的混淆解释；若未触发（A0 锚点更少且性能更好），直接在机制分析表中报告这一更有力的结果。

**推荐论文表述（可直接修改使用）：**

```text
Removing the BIC penalty (A1) increases the number of accepted splits and anchor 
count but usually degrades clustering quality, confirming that the BIC penalty is 
necessary to prevent over-segmentation. Replacing BIC-LR anchor generation with 
the original HBNC under the same downstream pipeline (A2) also reduces performance, 
showing that the likelihood-ratio-based split criterion contributes independently of 
the heuristic anchor discovery. For target-view selection, replacing BICUnitEvidence 
with SSEMin (A3) leads to inconsistent view choices across datasets (agreement rate: 
XX%), and clustering quality drops on YY/ZZ datasets, validating the BIC evidence 
criterion as a more reliable view-quality measure. Finally, removing multi-view 
fusion (A4) and relying only on the target view further degrades performance, 
indicating that the alignment-fusion pipeline is necessary for the BIC-LR improvements 
to transfer to final clustering results.
```
