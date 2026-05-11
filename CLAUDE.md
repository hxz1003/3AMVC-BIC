# CLAUDE.md — 3AMVC BIC-LR 改进项目上下文与代码审查规范

## 0. 使用范围

本文件用于 Claude Code 在 `mahuimin16/3AMVC` MATLAB 仓库中进行代码理解、实现、审查、调试和实验记录。

当前主线任务是：

> 在原始 3AMVC 的 MATLAB 实现基础上，将原 HBNC 锚点选择中的停止/划分判据改写为 **BIC 正则化似然比检验**，并保持原始 3AMVC 的锚图学习、跨视图锚点对齐、等权融合和最终谱嵌入聚类流程。

本文件不是通用 MATLAB 风格指南，而是当前 3AMVC + BIC-LR 改进任务的项目级约束。

---

## 1. 核心定位

你是一位负责 MATLAB 学术代码复现、改进和审查的算法工程助手。你的任务是围绕 3AMVC 论文和当前 BIC-LR 改进文档进行工程实现与代码审查。

必须遵守：

1. 所有回复、代码注释、函数帮助文本、测试说明、实验日志均使用中文。
2. 优先理解原项目调用链，再进行修改。
3. 优先新增 BIC-LR 路径，不破坏原始 HBNC 路径。
4. 优先保持原始 3AMVC 的对齐与等权融合结构。
5. 不得把之前加权融合版本中的 `rho`、`tauS`、`quality_weighted`、`quality_alignment_weighted` 当作当前主线方法。
6. 任何“优化”都必须先证明不改变数学含义，不能为了速度牺牲算法语义。

---

## 2. 参考依据

本项目规范以以下材料为准：

1. 原始论文：**Automatic and Aligned Anchor Learning Strategy for Multi-View Clustering**, ACM MM 2024, DOI: `10.1145/3664647.3681273`。
2. 原始仓库：`https://github.com/mahuimin16/3AMVC`。
3. 当前方法文档：`3AMVC的似然比改进 - 似然比检验锚点选择.md`。
4. 当前用户要求：使用 BIC 正则化似然比检验替换/扩展原 HBNC 的锚点生成逻辑；保留原论文等权融合。

若代码、旧版 CLAUDE 文件、旧版 AGENTS 文件与上述主线目标冲突，以当前方法文档和原始论文为准。

---

## 3. 原始 3AMVC 论文核心结论

原始 3AMVC 的动机包括：

1. 多视图聚类常用锚图降低完整图构造的二次复杂度。
2. 传统方法通常需要预设锚点数，导致额外调参开销。
3. 不同视图强行使用相同锚点数会限制单视图表征能力。
4. 3AMVC 使用 HBNC 在每个视图中自动学习锚点数量。
5. 3AMVC 根据锚图质量选择基准视图，再将其他视图的锚图对齐到该基准视图。
6. 对齐后执行等权融合，并对融合锚图做谱嵌入与 KMeans。

当前 BIC-LR 改进必须保留第 4—6 点的总体框架，只替换锚点选择中的局部划分/停止判据。

---

## 4. 当前主线算法流程

当前方法的逻辑链为：

```text
多视图数据 {X^(v)}
  -> 每个视图独立执行 BIC-LR 自适应锚点选择
  -> 得到视图特定锚点 Θ^(v)，锚点数 m_v 可不同
  -> 构造或学习单视图锚图 Z^(v)
  -> 依据簇内误差评价锚点质量 q_v
  -> 选择质量最高的基准视图 b
  -> 将其他视图锚图 Z^(v) 通过 P_v 对齐到基准视图锚点空间
  -> 对齐后的锚图执行等权融合
  -> 对融合锚图做 SVD / 谱嵌入
  -> 对左奇异向量执行 KMeans 得到最终聚类标签
```

不得把主线流程改为质量加权融合或质量-对齐联合加权融合。

---

## 5. 推荐 MATLAB 调用链

原始路径保留：

```text
demo.m
  -> Neighbor.m
       -> Pre_HBNC.m
       -> Impro_HBNC.m
       -> Pro_Out.m
       -> criterion.m
  -> algo_qp.m
       -> aligned.m
            -> DSPFP.m
  -> measure/myNMIACCwithmean.m
```

BIC-LR 新增路径建议：

```text
demo_biclr.m
  -> Neighbor_BICLR.m
       -> BIC_LR_HBNC.m
            -> biclr_best_split.m
            -> biclr_loglik_single.m
            -> biclr_loglik_double.m
            -> biclr_node_sse.m
  -> algo_qp.m
       -> aligned.m
            -> DSPFP.m
  -> measure/myNMIACCwithmean.m
```

原则：

1. `Neighbor.m` 原路径不要删除。
2. `Pre_HBNC.m`、`Impro_HBNC.m`、`criterion.m` 原逻辑不要直接改成 BIC-LR。
3. 新增 `Neighbor_BICLR.m` 与 `BIC_LR_HBNC.m`，用于并行保留新旧算法。
4. `algo_qp.m`、`aligned.m`、`DSPFP.m` 的接口尽量保持兼容。

---

## 6. 关键文件职责

| 文件 | 当前职责 | 修改原则 |
|---|---|---|
| `demo.m` | 原始或默认演示入口 | 不强行替换；可保留原始 HBNC 路径 |
| `demo_biclr.m` | BIC-LR 改进方法演示入口 | 推荐新增 |
| `Neighbor.m` | 原 HBNC 锚点生成包装函数 | 尽量不破坏 |
| `Neighbor_BICLR.m` | BIC-LR 锚点生成包装函数 | 推荐新增，接口尽量对齐 `Neighbor.m` |
| `BIC_LR_HBNC.m` | 递归 BIC-LR 自适应锚点选择主函数 | 推荐新增 |
| `biclr_best_split.m` | 当前节点最佳候选切分搜索 | 推荐新增 |
| `biclr_loglik_single.m` | 单簇模型对数似然 | 推荐新增 |
| `biclr_loglik_double.m` | 双簇模型对数似然 | 推荐新增 |
| `biclr_node_sse.m` | 节点均值与簇内平方误差 | 推荐新增 |
| `algo_qp.m` | 锚图学习与主优化 | 不随意改目标函数 |
| `aligned.m` | 跨视图对齐与融合 | 当前主线必须等权融合 |
| `DSPFP.m` | 匹配/排列矩阵求解 | 不随意改 |
| `measure/*` | 聚类评价指标 | 不改变评价口径 |

---

## 7. BIC-LR 锚点选择数学规范

### 7.1 局部假设

对每个视图独立递归二分。对于当前节点样本集 `C`：

```text
H0：C 由一个球形高斯分布生成。
H1：C 由两个共享方差的球形高斯子分布生成。
```

`H0` 表示当前节点已经足够紧凑，不需要继续分裂；`H1` 表示当前节点内部仍有可分结构，应继续二分。

### 7.2 单簇模型

对节点 `C`，设样本数为 `nC`，维度为 `d`：

```text
mu0 = mean(C, 1)
W0 = sum_i ||x_i - mu0||_2^2
sigma0Sq = W0 / (nC * d) + epsVar
logL0 = -(nC * d / 2) * (log(2*pi*sigma0Sq) + 1)
```

### 7.3 双簇模型

对候选划分 `C -> C1 ∪ C2`：

```text
n1 = size(C1, 1)
n2 = size(C2, 1)
pi1 = n1 / nC
pi2 = n2 / nC

mu1 = mean(C1, 1)
mu2 = mean(C2, 1)

W1 = sum_i ||x_i in C1 - mu1||_2^2
W2 = sum_i ||x_i in C2 - mu2||_2^2

sigma12Sq = (W1 + W2) / (nC * d) + epsVar

logL1 = n1 * log(pi1) + n2 * log(pi2) ...
        - (nC * d / 2) * (log(2*pi*sigma12Sq) + 1)
```

### 7.4 BIC 正则化似然比得分

对候选划分：

```text
S(C1, C2) = 2 * (logL1(C1, C2) - logL0(C)) ...
            - lambdaBIC * (d + 1) * log(nC)
```

若最佳候选划分满足：

```text
S_best > tauSplit
```

则接受分裂；否则停止分裂，并将当前节点中心作为锚点。

默认：

```matlab
params.tauSplit = 0;
```

含义：只有当双簇模型经过 BIC 复杂度惩罚后仍优于单簇模型时，才接受分裂。

---

## 8. 候选切分搜索规范

推荐采用投影扫描生成候选切分点，但似然必须在原始特征空间计算。

标准过程：

1. 对当前节点样本中心化。
2. 使用确定性方向作为投影方向，例如第一主方向。
3. 将样本投影到一维。
4. 按投影值排序。
5. 枚举满足 `minNodeSize` 的候选切分位置。
6. 对每个候选切分，在原始 `d` 维空间中计算 `logL0`、`logL1` 和 BIC-LR 得分。
7. 选择得分最高的候选切分。
8. 仅当 `S_best > tauSplit` 时接受切分。

禁止：

1. 只在一维投影空间计算似然。
2. 允许子节点样本数小于 `minNodeSize`。
3. 为了得到更多锚点而绕过 BIC 惩罚。
4. 将 `criterion.m` 的旧阈值判据复用为 BIC-LR 判据。

---

## 9. 单视图锚图学习与跨视图对齐

### 9.1 单视图锚图学习

锚图学习应保持 3AMVC 的基本形式：

```text
min_{Z^(v), Θ^(v)} ||X^(v) - Z^(v)Θ^(v)||_F^2 + beta * Ω(Z^(v))
s.t. Z^(v) >= 0, Z^(v) * 1 = 1
```

MATLAB 内部可能采用转置表示，应以项目实际维度为准，不能机械套用论文符号。

### 9.2 基准视图选择

锚点质量分数使用簇内平方误差，越小表示锚点越有代表性：

```text
q_v = sum_c sum_{x_j in cluster c} ||x_j - theta_c^(v)||_2^2
```

基准视图：

```text
b = argmin_v q_v
```

注意：这里是 `min`，不是 `max`。

### 9.3 跨视图对齐

对每个非基准视图 `v != b`，对齐目标应包含特征对应项和结构对应项：

```text
min_{P_v} ||Z^(b) - Z^(v)P_v||_F^2
         + lambda * ||G^(b) - P_v' G^(v) P_v||_F^2
```

`lambda` 是对齐阶段中特征对应与结构对应的权衡参数。

### 9.4 等权融合

当前 BIC-LR 改进主线必须使用等权融合：

```text
Z_aligned = (1 / V) * (Z^(b) + sum_{v != b} Z^(v) P_v)
```

如果代码内部没有除以 `V`，但后续谱嵌入对整体尺度不敏感，也必须在注释中说明尺度差异是否影响结果。默认建议使用平均形式，便于与方法文档一致。

---

## 10. 严禁误用加权融合版本

旧版 `CLAUDE.md` 中曾包含：

```text
quality_weighted
quality_alignment_weighted
rho
tauS
softmax weights
```

这些属于另一个加权融合改动，不是当前 BIC-LR + 原始 3AMVC 等权融合的主线。

当前主线要求：

1. 不搜索 `rho`。
2. 不搜索 `tauS`。
3. 不把 `quality_weighted` 作为默认融合模式。
4. 不把 `quality_alignment_weighted` 作为当前主方法。
5. 若代码中保留加权融合分支，只能作为兼容旧实验的非主线分支，并在注释中明确标注。
6. 审查时若发现 `demo_biclr.m` 默认启用加权融合，应判为算法语义错误。

---

## 11. 参数分类

必须区分“模型/实验超参数”和“工程控制参数”。

### 11.1 当前主搜索参数

当前主线推荐搜索：

```text
beta / lambda / lambdaBIC / minNodeSize
```

含义：

| 参数 | 所属阶段 | 含义 |
|---|---|---|
| `beta` | 锚图学习 | 锚图正则项或约束项权重 |
| `lambda` | 跨视图对齐 | 特征对应项与结构对应项的权衡 |
| `lambdaBIC` | BIC-LR 锚点选择 | BIC 惩罚强度，越大越保守，锚点通常越少 |
| `minNodeSize` | BIC-LR 锚点选择 | 子节点最小样本数，防止极小簇和过划分 |

### 11.2 默认固定参数

以下参数默认不参与主搜索：

```text
tauSplit
epsVar
maxAnchors
```

处理原则：

- `tauSplit`：理论上的分裂接受阈值，默认固定为 `0`。除非专门做阈值敏感性实验，否则不参与主搜索。
- `epsVar`：方差保护项，只用于防止 `log(0)` 和除零，属于数值稳定参数。
- `maxAnchors`：安全上限，只用于防止异常过划分，不应影响正常实验结果。

### 11.3 工程控制参数

```text
verbose
randomSeed
```

- `verbose`：日志开关，不影响算法数学结果。
- `randomSeed`：复现实验用随机种子，不是模型超参数。

若实现中使用随机二分、随机 KMeans 初始化或随机采样，必须记录 `randomSeed`。

---

## 12. 缓存与随机性规则

### 12.1 可缓存条件

若锚点选择结果只依赖：

```text
dataset / preprocess / lambdaBIC / minNodeSize / randomSeed
```

而后续只搜索：

```text
beta / lambda
```

则可以缓存 `Neighbor_BICLR` 或 `BIC_LR_HBNC` 的输出，避免每个 `beta/lambda` 组合重复生成锚点。

### 12.2 缓存键

缓存键至少包含：

```text
数据集名
预处理方式
视图编号
lambdaBIC
minNodeSize
tauSplit
epsVar
randomSeed
是否去除某些类别或限样
```

若任一项不同，不得复用同一份锚点缓存。

### 12.3 随机性口径

需要区分三种实验口径：

1. **只重复最终 KMeans 评价**：锚点可以固定，缓存有意义。
2. **重复完整算法随机性**：每个 seed 都应重新生成锚点，但可以按 seed 缓存。
3. **锚点生成完全确定性**：相同数据与相同参数下锚点应完全一致，缓存最合理。

审查时若发现所有 seed 共用同一份随机锚点缓存，应检查这是否符合实验口径。

---

## 13. 矩阵方向规则

论文常用：

```text
X^(v) ∈ R^{n × d_v}
Θ^(v) ∈ R^{m_v × d_v}
Z^(v) ∈ R^{n × m_v}
```

MATLAB 代码中可能使用转置形式，例如：

```text
X{i} 可能为 d_i × n
Zi{i} 可能为 m_i × n
```

必须先通过实际代码确认维度，再修改。

规则：

1. 不要为了消除报错而随意转置。
2. 每次转置都要说明语义。
3. 构造锚图后应检查非负性、列和/行和约束是否与当前内部约定一致。
4. `aligned.m`、`algo_qp.m`、`DSPFP.m` 之间的方向必须一致。
5. 如果论文符号与代码方向不同，以代码实际调用链为准，但需要在注释中说明。

---

## 14. 代码实现规范

### 14.1 新增函数规范

每个新增对外函数必须包含中文帮助文本：

```matlab
function [out1, out2] = func_name(in1, in2)
% FUNC_NAME 中文一句话说明。
%
% 输入：
%   in1 - 维度、含义
%   in2 - 维度、含义
%
% 输出：
%   out1 - 维度、含义
%   out2 - 维度、含义
%
% 注意：
%   说明数值稳定性、随机性、矩阵方向或兼容性。
```

### 14.2 输入检查

关键函数必须检查：

1. 输入是否为空。
2. 是否为数值矩阵或合法 cell。
3. 维度是否匹配。
4. 是否存在 `NaN` 或 `Inf`。
5. 参数是否在合法范围内。

### 14.3 数值稳定性

必须处理：

1. `log(0)`。
2. 除零。
3. 空簇。
4. 单样本节点。
5. 重复样本。
6. 极小方差。
7. 过小子节点。

默认使用：

```matlab
params.epsVar = 1e-12;
```

若调整该值，必须记录理由。

---

## 15. 公式一致性审查清单

审查 BIC-LR 改进时，逐项检查：

### 15.1 BIC-LR 锚点选择

- [ ] `BIC_LR_HBNC.m` 是否对每个视图独立递归生成锚点。
- [ ] 是否比较 `H0` 单球形高斯与 `H1` 两个共享方差球形高斯。
- [ ] 单簇方差是否为 `W0 / (nC*d) + epsVar`。
- [ ] 双簇共享方差是否为 `(W1+W2)/(nC*d) + epsVar`。
- [ ] `logL1` 是否包含 `n1*log(pi1) + n2*log(pi2)`。
- [ ] BIC 惩罚是否为 `lambdaBIC * (d+1) * log(nC)`。
- [ ] 是否用 `S_best > tauSplit` 决定是否分裂。
- [ ] 默认 `tauSplit` 是否为 `0`。
- [ ] 是否把停止节点的均值作为锚点。
- [ ] 是否返回每个样本的锚点标签。

### 15.2 候选切分

- [ ] 投影方向是否确定或受 `randomSeed` 控制。
- [ ] 投影是否只用于生成候选切分点。
- [ ] 似然、SSE、方差是否在原始特征空间计算。
- [ ] 是否强制两个子节点均满足 `minNodeSize`。
- [ ] 是否避免空簇和极小簇。

### 15.3 3AMVC 主流程

- [ ] 是否使用锚点质量最小的视图作为基准视图。
- [ ] 是否允许不同视图生成不同数量锚点。
- [ ] 是否保留跨视图对齐目标中的特征项与结构项。
- [ ] 是否执行等权融合，而非 softmax 加权融合。
- [ ] 是否对融合锚图做 SVD / 谱嵌入。
- [ ] 是否对左奇异向量执行 KMeans。

---

## 16. 严重错误判定

出现以下情况，应判定为严重问题：

1. 删除原始 HBNC 路径，导致无法对照实验。
2. BIC-LR 中没有 BIC 惩罚，只比较裸似然。
3. BIC 惩罚参数写错为 `d`、`2d+2` 或其他非当前文档定义的形式，且无说明。
4. `tauSplit` 被默认加入主网格搜索。
5. `rho`、`tauS` 被默认加入当前主线搜索。
6. 默认启用 `quality_weighted` 或 `quality_alignment_weighted`。
7. 强制所有视图锚点数相同。
8. 基准视图用 `max(q)` 而不是 `min(q)`。
9. 投影后只在 1D 空间算似然。
10. 不检查 `NaN/Inf`，导致错误结果静默传播。
11. 更改评价指标口径却声称与原论文可比。

---

## 17. 性能优化与等价性

允许的优化：

1. `norm(a-b)^2` 改为 `sum((A-B).^2, 2)`。
2. 循环累加改为 `cumsum` 或 `accumarray`。
3. 单列单纯形投影改为批量排序阈值法。
4. 与超参数无关的前处理结果缓存。
5. 重复 KMeans 评价用 `parfor`，前提是随机种子可复现。

不允许的优化：

1. 为加速而跳过部分候选切分，除非明确作为近似并记录。
2. 为加速而改变 BIC-LR 得分定义。
3. 为加速而强行限制锚点数，除非触发 `maxAnchors` 安全上限并记录。
4. 为加速而改变原始评价指标。
5. 为加速而默认减少 KMeans 重复次数但仍声称与原设置可比。

---

## 18. 测试要求

新增或修改 BIC-LR 代码后，至少进行以下测试：

1. 单个紧凑高斯簇应生成一个或很少锚点。
2. 两个明显分离的高斯簇应被分裂。
3. 重复样本不应产生 `NaN` 或 `Inf`。
4. `minNodeSize` 应阻止极小子节点。
5. 增大 `lambdaBIC` 时，锚点数通常不应增加。
6. 相同 `randomSeed` 下结果应可复现。
7. 不同视图可以生成不同数量锚点。
8. `demo_biclr.m` 能完整运行到最终指标输出。

测试输出至少包含：

```text
数据集名
视图数
每个视图锚点数
beta
lambda
lambdaBIC
minNodeSize
tauSplit
randomSeed
ACC / NMI / Purity / Fscore
运行时间
```

---

## 19. 实验记录规范

实验记录必须明确区分：

1. 原始 HBNC 路径。
2. BIC-LR 改进路径。
3. 是否使用缓存。
4. 是否固定锚点，仅重复最终 KMeans。
5. 是否每个 seed 重新生成锚点。
6. 是否去除数据集中的特殊类别。
7. 是否限样。
8. 是否开启并行。

不得将单次最优结果称为平均性能。

---

## 20. 审查输出格式

审查代码时使用以下格式：

```text
## 审查结果

### 严重问题（影响算法正确性）
- [文件:行号] 问题描述 | 修改建议

### 中等问题（影响可复现性、性能或接口兼容）
- [文件:行号] 问题描述 | 修改建议

### 轻微问题（风格、注释、日志）
- [文件:行号] 问题描述 | 修改建议

### 公式一致性检查
- [PASS/FAIL] BIC-LR 单簇似然
- [PASS/FAIL] BIC-LR 双簇似然
- [PASS/FAIL] BIC 惩罚项
- [PASS/FAIL] 分裂接受条件
- [PASS/FAIL] 基准视图选择
- [PASS/FAIL] 跨视图对齐目标
- [PASS/FAIL] 等权融合

### 性能与缓存检查
- [PASS/FAIL] 是否存在无意义重复锚点生成
- [PASS/FAIL] 缓存键是否包含随机种子和 BIC-LR 参数
- [PASS/FAIL] 向量化是否保持数学等价

### 最终结论
- 是否可以合并：是/否
- 必须先修复的问题：...
```

---

## 21. Claude Code 常用指令模板

### 21.1 审查 BIC-LR 实现

```text
请先阅读 CLAUDE.md，然后审查 BIC_LR_HBNC.m、biclr_best_split.m、biclr_loglik_single.m、biclr_loglik_double.m 是否严格符合 BIC-LR 公式。重点检查单簇似然、双簇似然、BIC 惩罚、minNodeSize、tauSplit 和数值稳定性。
```

### 21.2 审查主流程是否误用加权融合

```text
请按照 CLAUDE.md 检查 demo_biclr.m、algo_qp.m、aligned.m 是否保持原始 3AMVC 的等权融合。若发现默认使用 quality_weighted、quality_alignment_weighted、rho 或 tauS，请指出并修正。
```

### 21.3 执行最小测试

```text
请按照 CLAUDE.md 新增或运行 BIC-LR 的最小合成数据测试，验证紧凑单簇、双簇、重复样本、minNodeSize、lambdaBIC 单调性和 randomSeed 可复现性。
```

### 21.4 运行演示

```text
请运行 demo_biclr.m，记录每个视图的锚点数、参数设置、运行时间和最终聚类指标。不要修改原始 demo.m，除非有明确兼容需求。
```

---

## 22. 最终交付要求

完成实现或审查后，必须说明：

1. 修改了哪些文件。
2. 新增了哪些文件。
3. 是否保留原 HBNC 路径。
4. 是否默认使用 BIC-LR 路径。
5. 是否保持等权融合。
6. 是否搜索了正确的参数集合。
7. 是否运行了测试。
8. 是否运行了 `demo_biclr.m`。
9. 每个视图生成的锚点数。
10. 最终实验指标。
11. 未解决的问题。

不能在没有运行代码的情况下声称“测试通过”。如果没有运行，必须明确写出“尚未运行”。
