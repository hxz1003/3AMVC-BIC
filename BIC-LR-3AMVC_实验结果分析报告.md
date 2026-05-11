# BIC-LR-3AMVC 实验结果分析报告

## 一、读取到的结果文件

### 1.1 主模型 BIC-LR-3AMVC 结果文件

#### 1）粗搜索结果目录
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\Caltech101_all_BICLR_grid_20260509_204041.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\MFeat_2Views_BICLR_grid_20260509_200331.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\Reuters_1200_BICLR_grid_20260509_195924.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\Wikifea_BICLR_grid_20260509_200910.mat`

用途：
- 对应完整 `BIC-LR-3AMVC` 的粗网格搜索结果。
- 每个文件内为 `results` 结构体，包含多组参数记录。

主要字段：
- 顶层字段：`datasetName, meta, config, records, best, totalTime, savePath`
- `records/best` 中的核心字段：
  `beta, lambda, lambdaBIC, minNodeSize, tauSplit, epsVar, randomSeed, anchorCounts, targetView, anchorQuality, iter, objFinal, metricsMean, metricsStd, metricNames, algoTime, anchorTime, totalTime, useCache, cacheHit, cacheKeys, cacheFiles, numRuns, kmeansReplicates, useParallel`

#### 2）精细搜索结果目录
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Caltech101_all_BICLR_grid_20260510_004552.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\MFeat_2Views_BICLR_grid_20260509_225119.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Reuters_1200_BICLR_grid_20260509_224753.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Wikifea_BICLR_grid_20260509_225718.mat`

用途：
- 对应完整 `BIC-LR-3AMVC` 的精细搜索结果。

主要字段：
- 顶层字段：`datasetName, meta, config, records, best, bestIndex, selectionMetricName, totalTime, savePath`
- `best` 字段与粗搜索结果中的 `best` 结构一致。

#### 3）主模型最佳结果摘要文件
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Caltech101_all_BICLR_refined_best_ACC.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\MFeat_2Views_BICLR_refined_best_ACC.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Reuters_1200_BICLR_refined_best_ACC.mat`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Wikifea_BICLR_refined_best_ACC.mat`
- 对应 `.txt` 文件各 1 份

用途：
- 保存按 `ACC` 选出的最优配置摘要。

主要字段：
- `bestInfo` 结构体字段：
  `datasetName, selectionMetricName, sourceResultFile, beta, lambda, lambdaBIC, minNodeSize, tauSplit, epsVar, randomSeed, numRuns, kmeansReplicates, anchorCounts, targetView, metricsMean, metricsStd, metricNames, totalTime, cacheKeys`

说明：
- 这里的 `totalTime` 更像“整份搜索文件的总耗时摘要”，不是单个最优配置的纯运行耗时。
- 本报告中的运行时间分析统一以源 `.mat` 文件里 `results.best.totalTime` 为准。

### 1.2 主模型分析辅助文件

#### 1）CSV 结果表
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\selected_complete_results.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\biclr_all_selected_raw_results.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\biclr_top_configs.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\biclr_marginal_sensitivity.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\Caltech101_all_raw_results.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\MFeat_2Views_raw_results.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\Reuters_1200_raw_results.csv`
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\Wikifea_raw_results.csv`

用途与字段：
- `selected_complete_results.csv`
  - 用于记录每个数据集选中的正式完整实验文件。
  - 字段：`dataset, selectedFile, numRecords`
- `biclr_all_selected_raw_results.csv`
  - 用于记录完整模型粗搜索的逐参数原始结果。
  - 字段：`dataset, beta, lambda, lambdaBIC, minNodeSize, ACC, NMI, Purity, Fscore, anchorTotal, targetView, iter, algoTime, anchorTime, totalTime`
- `biclr_top_configs.csv`
  - 用于记录粗搜索中排名靠前的配置。
  - 字段：`dataset, rank, ACC, NMI, Purity, Fscore, beta, lambda, lambdaBIC, minNodeSize, anchorTotal, anchorCountByView`
- `biclr_marginal_sensitivity.csv`
  - 用于参数敏感性分析。
  - 字段：`dataset, parameter, level, meanACC, stdACC, maxACC, meanNMI, meanAnchorTotal, minAnchorTotal, maxAnchorTotal, nearOptimalRatio`
- `*_raw_results.csv`
  - 用于保存单数据集完整粗搜索的逐参数原始记录。

#### 2）TXT 分析摘要
- `D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr\analysis\biclr_sensitivity_summary.txt`

用途：
- 记录完整模型粗搜索阶段的超参数敏感性文字摘要。

### 1.3 三类消融实验结果文件

#### 1）w/o BIC
- 正式 coarse 文件：
  - `D:\matlab\3AMVC-BIC\ablation_wobic\res_coarse\Caltech101_all_wobic_grid_20260510_162107.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wobic\res_coarse\MFeat_2Views_wobic_grid_20260510_155600.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wobic\res_coarse\Reuters_1200_wobic_grid_20260510_155524.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wobic\res_coarse\Wikifea_wobic_grid_20260510_155651.mat`
- 早期烟雾测试文件：
  - `D:\matlab\3AMVC-BIC\ablation_wobic\res_coarse\MFeat_2Views_wobic_grid_20260510_152957.mat`

用途：
- `w/o BIC` 粗搜索结果。

主要字段：
- 顶层字段：`methodName, datasetName, meta, config, records, best, bestIndex, selectionMetricName, totalTime, savePath`
- `methodName = 'wobic'`

#### 2）w/o LR
- 正式 coarse 文件：
  - `D:\matlab\3AMVC-BIC\ablation_wolr\res_coarse\Caltech101_all_wolr_grid_20260510_160736.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wolr\res_coarse\MFeat_2Views_wolr_grid_20260510_153942.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wolr\res_coarse\Reuters_1200_wolr_grid_20260510_153854.mat`
  - `D:\matlab\3AMVC-BIC\ablation_wolr\res_coarse\Wikifea_wolr_grid_20260510_154018.mat`
- 早期烟雾测试文件：
  - `D:\matlab\3AMVC-BIC\ablation_wolr\res_coarse\MFeat_2Views_wolr_grid_20260510_152958.mat`

用途：
- `w/o LR` 粗搜索结果。

主要字段：
- 顶层字段同上。
- `methodName = 'wolr'`

#### 3）w/o alignment
- 正式 coarse 文件：
  - `D:\matlab\3AMVC-BIC\ablation_woalignment\res_coarse\Caltech101_all_woalignment_grid_20260510_162728.mat`
  - `D:\matlab\3AMVC-BIC\ablation_woalignment\res_coarse\MFeat_2Views_woalignment_grid_20260510_160438.mat`
  - `D:\matlab\3AMVC-BIC\ablation_woalignment\res_coarse\Reuters_1200_woalignment_grid_20260510_160534.mat`
  - `D:\matlab\3AMVC-BIC\ablation_woalignment\res_coarse\Wikifea_woalignment_grid_20260510_160351.mat`
- 早期烟雾测试文件：
  - `D:\matlab\3AMVC-BIC\ablation_woalignment\res_coarse\MFeat_2Views_woalignment_grid_20260510_152958.mat`

用途：
- `w/o alignment` 粗搜索结果。

主要字段：
- 顶层字段同上。
- `methodName = 'woalignment'`

### 1.4 锚点缓存文件

目录：
- `D:\matlab\3AMVC-BIC\3AMVC-main\cache\*.mat`
- `D:\matlab\3AMVC-BIC\ablation_wobic\cache\*.mat`
- `D:\matlab\3AMVC-BIC\ablation_wolr\cache\*.mat`
- `D:\matlab\3AMVC-BIC\ablation_woalignment\cache\*.mat`

用途：
- 保存单视图锚点生成缓存，不是最终论文结果表，但会影响 `anchorTime` 的解释。

示例字段：
- `theta, object, label_neighbor, info, qualityScore, anchorOptions, cacheKey, methodName`
- 主模型缓存还包含 `labelField`

说明：
- `qualityScore = sum(object)`，数值越小表示该视图锚点簇内总 SSE 越小。
- 基准视图由 `min(qualityScore)` 选出。

### 1.5 原始 3AMVC/HBNC 对比材料

找到的相关材料：
- 原始论文 PDF：`D:\matlab\3AMVC-BIC\3664647.3681273.pdf`
- 项目说明：`D:\matlab\3AMVC-BIC\3AMVC-main\README.md`

当前未发现的内容：
- 未发现一份独立、明确、可直接用于本地数值对齐的 `Original 3AMVC / HBNC-3AMVC` 结果 `.mat/.csv/.txt` 文件。
- 未发现 `.xlsx` 结果表。

结论：
- 当前仓库中“完整实验”和“三类消融实验”结果是充分的。
- “Original 3AMVC/HBNC 本地复现实验结果”当前缺失，只能借助原论文 PDF 做趋势对照，不能完成完全严格的本地一对一数值比较。

## 二、实验方法与命名统一

### 2.1 论文统一命名

| 论文名称 | 当前结果中的原始命名/来源 | 说明 |
|---|---|---|
| M1 Original 3AMVC / HBNC-3AMVC | 论文与 README 中的 `3AMVC`, `HBNC` | 当前仓库未发现独立本地结果文件 |
| M2 BIC-LR-3AMVC | 文件名中的 `BICLR`，如 `*_BICLR_grid_*.mat` | 当前主方法 |
| M3 w/o BIC | `methodName='wobic'` | 去掉 BIC 惩罚项 |
| M4 w/o LR | `methodName='wolr'` | 去掉似然比建模 |
| M5 w/o alignment | `methodName='woalignment'` | 不执行跨视图对齐，当前实现为基准视图单视图聚类 |

### 2.2 命名一致性检查

- 完整模型结果文件主要使用 `BICLR` 命名，建议论文统一写成 `BIC-LR-3AMVC`。
- `wobic / wolr / woalignment` 与论文写法不一致，建议统一改写为：
  - `wobic -> w/o BIC`
  - `wolr -> w/o LR`
  - `woalignment -> w/o alignment`
- 数据集命名存在文件名与结构体字段差异：
  - 文件名：`Reuters_1200`，结构体：`Reuters-1200`
  - 文件名：`Caltech101_all`，结构体：`Caltech101-all`
- 结果文件中没有出现 `quality_weighted`、`quality_alignment_weighted`、`rho`、`tauS` 作为主线方法命名，符合当前主线设定。

## 三、主实验结果分析

### 3.1 当前完整模型最优结果

说明：
- 以下结果均来自正式结果文件。
- 模型选择标准为 `best ACC`。
- `AR` 在代码中实际对应 `ARI`，因为底层 `RandIndex.m` 返回的是 Hubert & Arabie adjusted Rand index。

| Dataset | ACC | NMI | Purity | Fscore | Precision | Recall | ARI | Runtime | AnchorNums | MeanAnchors | BaselineView | AnchorQuality |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|---|
| Caltech101-all | 0.2877 | 0.4488 | 0.4241 | 0.2214 | 0.3231 | 0.1685 | 0.2060 | 66.93s | [113,114,116,99,111,114] | 111.17 | 5 | [1.05e7, 4.68e5, 1.81e9, 1.36e5, 2890, 8642] |
| MFeat_2Views | 0.9053 | 0.8403 | 0.9053 | 0.8272 | 0.8217 | 0.8327 | 0.8079 | 0.57s | [35,39] | 37.00 | 1 | [346.9, 1.349e6] |
| Reuters-1200 | 0.5994 | 0.3472 | 0.6043 | 0.4211 | 0.4083 | 0.4350 | 0.3015 | 3.95s | [34,32,35,31,32] | 32.80 | 3 | [7.079e5, 7.087e5, 6.863e5, 7.011e5, 6.881e5] |
| Wikifea | 0.5674 | 0.5178 | 0.6059 | 0.4793 | 0.4891 | 0.4699 | 0.4178 | 2.44s | [21,43] | 32.00 | 1 | [40.07, 41.86] |

### 3.2 与 Original 3AMVC/HBNC 的可比性结论

严格数值对比结论：
- 当前仓库中未发现本地 `Original 3AMVC / HBNC-3AMVC` 的结果文件。
- 因此，无法基于“相同代码环境、相同预处理、相同评价重复次数”计算四个数据集上 `BIC-LR-3AMVC` 相对 `Original 3AMVC` 的严格本地绝对提升和相对提升。

当前结果不足以支撑的结论：
- 不能声称“BIC-LR-3AMVC 在四个当前数据集上均严格优于本地 Original 3AMVC”。
- 不能给出 Caltech101-all 与 Wikifea 相对 Original 3AMVC 的严格本地提升百分比。

### 3.3 与原论文 3AMVC 结果的趋势对照

说明：
- 以下仅对 `Reuters-1200` 与 `MFeat_2Views` 做趋势对照。
- 原始 3AMVC 论文表 2 可从 PDF 文本中抽取到 `ACC/NMI/Fscore`，但仍建议写论文时人工复核 PDF 表格。
- `Caltech101-all` 与原论文中的 `Caltech256` 不是同一数据集。
- `Wikifea` 不在原论文主实验数据集中。

| Dataset | 指标 | 当前 BIC-LR-3AMVC | 原论文 3AMVC | 绝对提升 | 相对提升 |
|---|---|---:|---:|---:|---:|
| Reuters-1200 | ACC | 0.5994 | 0.5734 | +0.0260 | +4.53% |
| Reuters-1200 | NMI | 0.3472 | 0.3316 | +0.0156 | +4.72% |
| Reuters-1200 | Fscore | 0.4211 | 0.4061 | +0.0150 | +3.70% |
| MFeat_2Views | ACC | 0.9053 | 0.8737 | +0.0316 | +3.62% |
| MFeat_2Views | NMI | 0.8403 | 0.8240 | +0.0163 | +1.97% |
| MFeat_2Views | Fscore | 0.8272 | 0.7986 | +0.0286 | +3.58% |

趋势判断：
- 在可对齐的 `Reuters-1200` 与 `MFeat_2Views` 上，当前 `BIC-LR-3AMVC` 相对原论文报告的 `3AMVC` 呈现稳定正向提升。
- 但这属于“论文报告结果 vs 当前仓库改进结果”的跨实验协议对照，不能替代本地同协议基线实验。

## 四、三类消融实验结果分析

### 4.1 w/o BIC

#### 4.1.1 最优结果对比

| Dataset | BIC-LR-3AMVC ACC | w/o BIC ACC | dACC | dNMI | dPurity | dFscore | AnchorTotal(main/ablation) | Runtime(main/ablation) |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Caltech101-all | 0.2877 | 0.2803 | +0.0074 | -0.0005 | +0.0007 | +0.0237 | 667 / 1053 | 66.93 / 78.09 |
| MFeat_2Views | 0.9053 | 0.9133 | -0.0080 | -0.0101 | -0.0080 | -0.0148 | 74 / 74 | 0.57 / 8.17 |
| Reuters-1200 | 0.5994 | 0.5635 | +0.0358 | -0.0014 | +0.0407 | +0.0223 | 164 / 310 | 3.95 / 14.19 |
| Wikifea | 0.5674 | 0.4817 | +0.0857 | +0.0594 | +0.0687 | +0.1040 | 64 / 117 | 2.44 / 5.62 |

#### 4.1.2 结论分析

- `w/o BIC` 在 `Caltech101-all`、`Reuters-1200`、`Wikifea` 上都产生了明显更多的锚点，尤其是 `Reuters-1200` 从 164 增加到 310，`Wikifea` 从 64 增加到 117，说明去掉复杂度惩罚后更容易继续划分。
- 在这三个数据集上，更多锚点并没有带来更高的 `ACC/Purity/Fscore`，反而整体下降，支持“BIC 惩罚可以抑制过划分”的主张。
- `MFeat_2Views` 是一个例外。该数据集上 `w/o BIC` 与完整模型的锚点数完全相同，且 `ACC` 略高 0.0080。这说明在该数据集当前最佳 coarse 配置附近，BIC 项并没有改变最终分裂结构，或者 MFeat 的局部结构足够简单，去掉 BIC 也不会明显导致过划分。
- 因此，本组结果总体支持 BIC 的必要性，但不能把这个结论写成“对所有数据集无例外成立”。

#### 4.1.3 是否支持“BIC 抑制过划分”

支持程度：
- `Reuters-1200`：强支持。锚点数近乎翻倍但性能下降。
- `Wikifea`：强支持。锚点数显著增加且多指标同步下降。
- `Caltech101-all`：中等支持。性能提升幅度不大，但锚点数显著增加且运行时间变长。
- `MFeat_2Views`：不支持该结论的普适性，说明该数据集上的 BIC 影响较弱。

### 4.2 w/o LR

#### 4.2.1 最优结果对比

| Dataset | BIC-LR-3AMVC ACC | w/o LR ACC | dACC | dNMI | dPurity | dFscore | AnchorTotal(main/ablation) | Runtime(main/ablation) |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Caltech101-all | 0.2877 | 0.2887 | -0.0010 | +0.0024 | +0.0051 | +0.0169 | 667 / 1052 | 66.93 / 148.68 |
| MFeat_2Views | 0.9053 | 0.8876 | +0.0177 | +0.0160 | +0.0177 | +0.0195 | 74 / 76 | 0.57 / 4.50 |
| Reuters-1200 | 0.5994 | 0.5498 | +0.0496 | +0.0291 | +0.0545 | +0.0355 | 164 / 155 | 3.95 / 9.98 |
| Wikifea | 0.5674 | 0.5274 | +0.0400 | +0.0373 | +0.0490 | +0.0511 | 64 / 110 | 2.44 / 2.41 |

#### 4.2.2 结论分析

- `w/o LR` 在 `MFeat_2Views`、`Reuters-1200`、`Wikifea` 上均明显弱于完整模型，说明仅凭非似然准则进行二分判断，不足以稳定捕获更有判别力的局部结构。
- `Reuters-1200` 上，`w/o LR` 的锚点总数甚至略少于完整模型，但性能下降更明显，这很关键。这说明 LR 的作用不是“单纯增加锚点”，而是改善“分裂是否合理”的统计判断。
- `Wikifea` 上，`w/o LR` 同时出现锚点数变多和性能下降，也支持经验型准则更容易产生低质量分裂。
- `Caltech101-all` 是另一处异常：`w/o LR` 的 `ACC` 比完整模型高 0.0010，但 `NMI/Purity/Fscore` 均低于完整模型，而且锚点数从 667 激增到 1052，总时间显著变长。这更像“按 best ACC 选优导致的单指标偶然占优”，不构成对 LR 必要性的实质反证。

#### 4.2.3 是否支持“似然建模优于简单经验准则”

总体结论：
- 支持。

理由：
- 4 个数据集里有 3 个在 `ACC/NMI/Purity/Fscore` 上都更优。
- 关键反例 `Caltech101-all` 只是在 `ACC` 上出现 0.001 量级的微弱反超，但结构型指标更差、锚点更多、耗时更长。
- 因而更稳妥的论文表述应为：
  “在大多数数据集上，似然比建模能够带来更稳定的锚点划分质量，并提升最终聚类性能；个别数据集上 ACC 的微弱波动不改变这一总体趋势。”

### 4.3 w/o alignment

#### 4.3.1 最优结果对比

| Dataset | BIC-LR-3AMVC ACC | w/o alignment ACC | dACC | dNMI | dPurity | dFscore | AnchorTotal(main/ablation) | Runtime(main/ablation) |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Caltech101-all | 0.2877 | 0.2884 | -0.0007 | +0.0227 | +0.0319 | -0.0089 | 667 / 730 | 66.93 / 31.10 |
| MFeat_2Views | 0.9053 | 0.5660 | +0.3393 | +0.3150 | +0.3164 | +0.3809 | 74 / 98 | 0.57 / 7.97 |
| Reuters-1200 | 0.5994 | 0.5302 | +0.0692 | +0.0409 | +0.0634 | +0.0373 | 164 / 164 | 3.95 / 135.10 |
| Wikifea | 0.5674 | 0.5242 | +0.0432 | +0.0329 | +0.0312 | +0.0384 | 64 / 63 | 2.44 / 1.04 |

#### 4.3.2 结论分析

- `MFeat_2Views` 上，`w/o alignment` 的 `ACC` 从 0.9053 直接降到 0.5660，是最强的证据，说明单视图锚点质量提升后，跨视图不对齐仍然会严重破坏融合效果。
- `Reuters-1200` 上，`w/o alignment` 与完整模型的锚点总数完全一样，说明性能差异主要来自“是否对齐”，而不是“锚点数变化”。这非常有力地支持了 3AMVC 原论文关于“不同视图锚点不对应时需要对齐”的观点。
- `Wikifea` 上，锚点总数几乎不变，但 `ACC/NMI/Purity/Fscore` 全部下降，也同样说明对齐模块不是可有可无的后处理，而是多视图融合成立的前提。
- `Caltech101-all` 上出现了另一个异常：`w/o alignment` 的 `ACC` 略高 0.0007，但 `NMI/Purity` 明显更低。这意味着按 `best ACC` 选优时，可能出现局部标签匹配更好但整体聚类结构更差的情况。因此不能只看单一 ACC。

#### 4.3.3 与原论文对齐模块的关系

需要强调：
- 当前仓库中的 `w/o alignment` 实现是“跳过跨视图对齐，退化为基准视图单视图聚类”。
- 原论文中的对齐消融更接近“仍做对齐，但统一按第一视图对齐，而不是按质量最优基准视图对齐”。
- 因此，两者不是完全相同的消融定义。
- 但是，两者都指向同一核心问题：跨视图锚点之间缺少可靠的语义对应时，最终融合性能会下降。

## 五、与原始 3AMVC/HBNC 论文结果对比

### 5.1 原论文实验主张

根据 `3664647.3681273.pdf` 可整理出原始 3AMVC/HBNC 的核心实验主张：
- 自动选择锚点优于固定锚点数方案，避免手工预设锚点数。
- 不同视图允许有不同数量的锚点。
- 应优先选择锚点质量更高的视图作为基准视图。
- 对齐后融合优于不对齐或劣质对齐。
- 锚图策略可以降低大规模多视图聚类的复杂度。

论文证据：
- 表 2 报告了 3AMVC 相对多种基线方法的优势。
- 表 3 通过“去掉自动锚点选择”和“去掉基准视图对齐”的消融，说明自动选锚点与对齐策略都有效。
- 文中明确指出：
  - 自动锚点策略避免了预定义锚点数。
  - 基准视图应来自锚点质量最高的视图。

### 5.2 当前 BIC-LR 改进与原论文关系

当前 `BIC-LR-3AMVC` 与原始 `3AMVC/HBNC` 的关系是“局部替换锚点递归停止准则”，而不是推翻原框架：
- 原 HBNC 关注经验性的代表性差异或层次划分停止规则。
- 当前 BIC-LR 把“是否继续分裂”改成了“单簇 vs 双簇”的统计模型选择。
- `lambdaBIC` 用于惩罚复杂模型，避免无限细分。
- `minNodeSize` 用于抑制极小节点和异常锚点。
- 后续的 3AMVC 对齐、等权融合和聚类评价框架保持不变。

因此，本文改进的理论定位应写成：
- “在保留原始 3AMVC 多视图对齐与等权融合主线的基础上，本文以 BIC 正则化似然比模型替换 HBNC 中经验性的继续划分判据，从而获得更稳健的视图自适应锚点。”

### 5.3 当前结果是否支持本文改进动机

支持的方面：
- `w/o BIC` 在大多数数据集上生成更多锚点但性能不升反降，支持“单纯增加锚点数并不一定更好”。
- `w/o LR` 在大多数数据集上性能下降，支持“经验式二分准则不如统计模型选择稳定”。
- `w/o alignment` 在 `MFeat_2Views`、`Reuters-1200`、`Wikifea` 上显著下降，说明单视图锚点质量改善后仍然需要跨视图对齐。

不能过度写大的地方：
- 当前没有本地 Original 3AMVC 结果文件，因此“相对原始 HBNC 全面提升”的结论还不能写得过满。
- `Caltech101-all` 上存在个别消融在 `ACC` 上微弱反超的情况，需要如实汇报。

## 六、参数敏感性分析

说明：
- 当前仓库中只发现了完整模型 `BIC-LR-3AMVC` 的参数敏感性结果。
- 没有发现三类消融实验对应的参数敏感性专门结果文件。

### 6.1 lambdaBIC

从 `biclr_marginal_sensitivity.csv` 可见：

- `Caltech101-all`
  - `lambdaBIC` 从 1 增大到 4 时，平均锚点总数从 581 降到 306.7。
  - 平均 `ACC` 从 0.2531 降到 0.2309。
  - 说明该数据集上过强惩罚会欠划分。

- `MFeat_2Views`
  - `lambdaBIC` 从 0.5 增大到 2 时，平均锚点总数从 182.7 降到 91.33。
  - 平均 `ACC` 从 0.5752 升到 0.6594。
  - 说明更强的复杂度控制有助于去除冗余划分。

- `Reuters-1200`
  - `lambdaBIC` 从 0.5 到 1 时，平均 `ACC` 从 0.4532 升到 0.4690。
  - 当 `lambdaBIC=2` 时，平均锚点总数仅剩 12.67，平均 `ACC` 降到 0.3555。
  - 说明该数据集存在明显“先升后降”，过大惩罚会严重欠划分。

- `Wikifea`
  - `lambdaBIC` 从 0.5 增大到 4 时，平均锚点总数从 261.7 降到 61。
  - 平均 `ACC` 从 0.2817 升到 0.3642。
  - 说明当前搜索范围内更强的 BIC 惩罚是有益的。

总体结论：
- `lambdaBIC` 对锚点数控制非常敏感。
- 不同数据集最优 `lambdaBIC` 不同。
- 可以合理写成“`lambdaBIC` 主要控制模型复杂度，在过小和过大之间存在数据集相关的折中”。

### 6.2 minNodeSize

趋势：
- `Caltech101-all`
  - `minNodeSize` 从 40 增大到 160，平均锚点总数从 693.7 降到 243。
  - 平均 `ACC` 从 0.2498 下降到 0.2320。
- `MFeat_2Views`
  - `minNodeSize` 从 10 增大到 40，平均锚点总数从 234 降到 72.67。
  - 平均 `ACC` 从 0.5270 升到 0.6904。
- `Reuters-1200`
  - `minNodeSize` 从 8 增大到 32，平均锚点总数从 76 降到 35.67。
  - 平均 `ACC` 呈现非单调变化，8 最好，16 最差，32 回升但仍不及 8。
- `Wikifea`
  - `minNodeSize` 从 10 到 20，平均 `ACC` 略升；到 40 又下降。
  - 说明中等粒度更合适。

总体结论：
- `minNodeSize` 增大通常会减少锚点数。
- 过小会带来噪声锚点和过度细分风险。
- 过大又可能吞并局部结构，导致欠划分。

### 6.3 beta 与 lambda

`beta`：
- 在 `MFeat_2Views` 和 `Wikifea` 上对平均 `ACC` 很敏感。
- 在 `Caltech101-all` 和 `Reuters-1200` 上也有影响，但弱于前两者。
- 说明锚图学习正则强度确实需要搜索。

`lambda`：
- 在当前粗搜索范围内，对平均 `ACC` 的影响整体较小。
- `Caltech101-all` 的边际敏感度排序中，`lambda` 排名最后。
- `Reuters-1200` 的 `lambda` 影响也很弱。
- 可以写成：
  “在当前搜索区间内，`lambda` 对性能的影响相对平缓，主敏感因子更多来自 `beta`、`lambdaBIC` 与 `minNodeSize`。”

## 七、锚点数量与锚点质量分析

### 7.1 锚点数量分布

完整模型下每视图锚点数：
- `Caltech101-all`：`[113,114,116,99,111,114]`
- `MFeat_2Views`：`[35,39]`
- `Reuters-1200`：`[34,32,35,31,32]`
- `Wikifea`：`[21,43]`

观察：
- `Caltech101-all` 与 `Reuters-1200` 的跨视图锚点数较均衡。
- `Wikifea` 的两视图锚点数差异较大，说明视图间局部结构复杂度不同。
- 这正是 3AMVC/当前改进方法需要跨视图对齐的背景之一。

### 7.2 锚点质量分数解释

当前实现中：
- `anchorQuality = sum(object)`
- `targetView = argmin(anchorQuality)`

因此：
- 该分数越小，说明该视图锚点对应的簇内总 SSE 越小。
- 它是“越小越好”的分数，不是“越大越好”。
- 该分数主要适合在同一数据集内部比较不同视图，不适合跨数据集直接比较绝对值。

### 7.3 基准视图选择现象

完整模型基准视图：
- `Caltech101-all`：视图 5
- `MFeat_2Views`：视图 1
- `Reuters-1200`：视图 3
- `Wikifea`：视图 1

说明：
- `Caltech101-all` 与 `Reuters-1200` 的基准视图在不同方法间较稳定。
- `Wikifea` 的基准视图在主模型和部分消融之间发生切换，说明该数据集的视图质量排序更敏感。

### 7.4 锚点数与性能关系

当前结果表明：
- 更大的锚点数不保证更好的聚类结果。
- `w/o BIC` 在多个数据集上锚点显著增多，但性能下降。
- `w/o LR` 在部分数据集上锚点数变化不大甚至略少，但性能仍下降。
- 因此，性能提升来自“更合理的锚点划分”，而不是“更多锚点”本身。

## 八、运行时间分析

### 8.1 当前结果文件实际记录了什么

当前结果文件中可直接读取的时间字段只有：
- `anchorTime`
- `algoTime`
- `totalTime`

其中：
- `anchorTime` 对应锚点生成阶段。
- `algoTime` 是一个聚合时间，当前实现里包含了 `algo_qp` 与 `myNMIACCwithmean`，因此不能被解释为“纯锚图学习/纯对齐时间”。
- `totalTime = anchorTime + algoTime`，结果文件没有单独记录“最终 KMeans 评价时间”。

因此，当前结果不足以支撑以下精细拆分：
- 单独的 `aligned` 耗时；
- 单独的最终 KMeans 评价耗时。

### 8.2 缓存对时间解释的影响

关键事实：
- `MFeat_2Views` 与 `Reuters-1200` 的完整模型最优记录是缓存命中，`cacheHit` 全为 `true`，因此 `anchorTime=0`。
- 多数消融记录是首次生成锚点，`cacheHit` 为 `false`，因此 `anchorTime` 较高。

这意味着：
- 当前单条记录的 `Runtime` 不能直接视为严格公平的算法复杂度比较。
- 它更适合作为“在当前缓存状态下的工程运行表现”。

### 8.3 现有时间现象

- `w/o BIC` 通常比完整模型更慢，和更多锚点数一致。
- `w/o LR` 在 `Caltech101-all` 上明显更慢，可能与大量无效分裂和更高的锚点数量有关。
- `w/o alignment` 在 `MFeat_2Views`、`Wikifea` 上没有表现出完整模型那样的融合开销，但性能显著下降。
- `Reuters-1200` 的 `w/o alignment` 出现了 `anchorTime=127.93s` 的异常大值，这不符合其锚点总数与主模型一致的直觉，需要在论文中标注为运行时间异常点，避免过度解读。

### 8.4 可以写进论文的稳妥结论

- 完整模型的额外开销主要来自更严格的锚点选择与后续多视图对齐。
- 在若干数据集上，这一额外开销换来了更高的聚类质量。
- 由于当前记录受缓存命中状态影响，运行时间更适合作定性分析，不宜直接作为严格公平的复杂度结论。

## 九、异常结果与原因解释

### 9.1 完整模型不如某个消融组

#### 1）MFeat_2Views 上 w/o BIC 的 ACC 更高
- 现象：`0.9133 > 0.9053`
- 可能原因：
  - 两者锚点数完全相同，说明在该数据集上 BIC 项对最终分裂结构几乎没有产生实质影响。
  - `w/o BIC` 只做了 coarse 搜索，完整模型做了 refined 搜索，但两者重复次数不同，存在选择偏差。
  - 差异量级仅 0.008，可能属于相近配置间的波动。

#### 2）Caltech101-all 上 w/o LR 的 ACC 略高
- 现象：`0.2887 > 0.2877`
- 但同时：
  - `NMI/Purity/Fscore` 都不如完整模型；
  - 锚点数大幅增加；
  - 总时间显著增加。
- 解释：
  - 当前所有方法都按 `best ACC` 选优，单一指标局部占优并不代表整体结构更好。

#### 3）Caltech101-all 上 w/o alignment 的 ACC 也略高
- 现象：`0.2884 > 0.2877`
- 但 `NMI` 下降 0.0227，`Purity` 下降 0.0319。
- 解释：
  - 当前 `w/o alignment` 的实现是“单基准视图聚类”，这可能在标签匹配层面偶然占优，但破坏了整体多视图结构一致性。

### 9.2 w/o alignment 效果接近完整模型

只在 `Caltech101-all` 的 `ACC` 上接近，其他三个数据集都明显下降。

合理解释：
- 该数据集类别多、视图多，单一 `ACC` 的微小波动很容易受到聚类匹配影响。
- 但从 `NMI/Purity` 看，完整模型仍然更稳健。

### 9.3 锚点数异常大或异常小

- `w/o BIC` 与 `w/o LR` 在 `Caltech101-all` 上都生成约 1050 个锚点，明显高于完整模型的 667。
- `Reuters-1200` 在 `lambdaBIC=2` 的粗搜索敏感性统计下，平均总锚点数可降到 12.67，说明过强惩罚会导致极端欠划分。

### 9.4 Runtime 异常

- `Reuters-1200 w/o alignment` 的 `anchorTime` 为 127.93s，远高于同数据集其他方法。
- 当前结果文件中没有额外日志可以解释该异常。
- 建议在论文正文只做简要说明，在补充材料中单独标注该点。

### 9.5 ACC 与 NMI 趋势不一致

典型案例：
- `Caltech101-all` 的 `w/o alignment` 与 `w/o LR` 在 `ACC` 上略高于完整模型，但 `NMI/Purity` 更低。

说明：
- 当前实验选择标准是 `best ACC`，因此最优点不一定同时也是 `NMI/Purity/Fscore` 的最优点。
- 写论文时必须强调“其余指标同步报告，但模型选优按 ACC 执行”。

### 9.6 随机性稳定性

当前已知事实：
- 所有结果的 `randomSeed=1`。
- 结果中的均值与标准差来自 `myNMIACCwithmean` 的重复 KMeans 评价，不是完整管线多 seed 重复。

因此当前结果不足以支撑：
- “完整算法对随机种子稳定”的结论；
- 多 seed 箱线图或方差分析。

## 十、可写入论文的实验分析段落

### 10.1 实验设置

本文在 `Caltech101-all`、`MFeat_2Views`、`Reuters-1200` 和 `Wikifea` 四个多视图数据集上评估所提出的 `BIC-LR-3AMVC` 方法。当前结果文件表明，四个数据集均采用 `raw` 预处理标签，未启用 `removeClutter`，也未进行 `maxPerClass` 限样。完整模型保留原始 3AMVC 的跨视图对齐与等权融合框架，仅将单视图锚点递归划分中的 HBNC 停止准则替换为 BIC 正则化似然比判据。参数方面，主线搜索变量包括 `beta`、`lambda`、`lambdaBIC` 与 `minNodeSize`，其中 `tauSplit=0`、`epsVar=1e-8`、`randomSeed=1` 为固定工程参数。评价指标包括 `ACC`、`NMI`、`Purity`、`Fscore`、`Precision`、`Recall` 与 `ARI`。需要说明的是，当前结果的最优模型均按 `best ACC` 选择，其余指标用于同步报告而非选优。

运行重复设置上，完整模型的精细搜索采用 `6~10` 次重复与 `3~4` 次 KMeans replicate，而当前三类消融实验仅完成 coarse 阶段，通常采用 `3~4` 次重复与 `2` 次 KMeans replicate。因此，消融结果在统计稳定性上弱于完整模型，这一点在后文讨论中将作为解释限制保留。运行环境信息未在当前结果文件中显式记录，需在论文定稿前补充。

### 10.2 主实验分析

从完整模型结果来看，`BIC-LR-3AMVC` 在四个数据集上分别取得了 `0.2877`、`0.9053`、`0.5994` 和 `0.5674` 的 `ACC`。其中，`MFeat_2Views` 与 `Reuters-1200` 是与原始 3AMVC 论文数据集可直接对应的两组实验。根据原论文表 2 的报告结果，3AMVC 在 `MFeat` 与 `Reuters` 上的 `ACC` 分别为 `0.8737` 和 `0.5734`，而当前改进模型达到 `0.9053` 和 `0.5994`，对应绝对提升分别为 `0.0316` 和 `0.0260`。在 `NMI` 与 `Fscore` 上也观察到一致的正向变化。这表明，在保持原始 3AMVC 多视图对齐与等权融合主线不变的前提下，用 BIC 正则化似然比替代 HBNC 的经验性划分判断，能够进一步改善视图自适应锚点的质量，并传导至最终聚类性能。

需要强调的是，当前仓库中未发现与本文结果完全同协议的 `Original 3AMVC/HBNC` 本地复现实验文件，因此对 `Caltech101-all` 与 `Wikifea` 不能给出严格的一对一数值提升结论。特别是 `Caltech101-all` 与原论文使用的 `Caltech256` 并非同一数据集，因此只能作趋势性讨论而不能作严格数值对照。

### 10.3 消融实验分析

`w/o BIC` 的结果表明，去掉复杂度惩罚后，`Reuters-1200` 与 `Wikifea` 上的锚点总数显著增加，但 `ACC`、`Purity` 与 `Fscore` 反而下降，说明单纯增加锚点并不能保证更好的聚类效果，BIC 项对于抑制过划分具有实际作用。不过，`MFeat_2Views` 上 `w/o BIC` 与完整模型取得了相同的锚点数，并在 `ACC` 上略有反超，说明该数据集上 BIC 项的影响较弱，或者其局部结构足够简单，以致去掉 BIC 后不会引发明显的无效分裂。因此，更稳妥的结论应是：BIC 惩罚在大多数数据集上有助于约束模型复杂度，但其收益具有数据集相关性。

`w/o LR` 的结果进一步说明了统计建模的必要性。尽管该变体在 `Caltech101-all` 上的 `ACC` 略高于完整模型，但其 `NMI`、`Purity` 与 `Fscore` 均更低，同时锚点数和运行开销显著增加。更关键的是，在 `Reuters-1200` 上，`w/o LR` 的锚点总数并没有增加，甚至略少于完整模型，但聚类性能却明显下降。这说明 LR 的价值不在于“产生更多锚点”，而在于为“是否继续划分”提供更合理的统计模型选择依据，使得最终锚点结构更有利于后续多视图聚类。

`w/o alignment` 的结果则验证了跨视图对齐模块的必要性。尤其在 `MFeat_2Views` 上，完整模型与 `w/o alignment` 之间的 `ACC` 差距达到 `0.3393`，在 `Reuters-1200` 与 `Wikifea` 上也观察到显著下降。值得注意的是，`Reuters-1200` 上完整模型与 `w/o alignment` 使用了相同的锚点总数，但后者仍出现明显性能下降，说明性能差异主要来自“对齐缺失”而非“锚点数变化”。这与原始 3AMVC 的核心观点一致，即便单视图锚点已经较优，不同视图之间仍然需要建立可靠的锚点对应关系，才能获得高质量的共识锚图。

### 10.4 参数敏感性分析

根据当前保存的 `biclr_marginal_sensitivity.csv`，`lambdaBIC` 与 `minNodeSize` 对锚点数和性能均具有显著影响。整体而言，增大 `lambdaBIC` 会明显减少锚点数，但其对性能的影响具有数据集依赖性：在 `MFeat_2Views` 与 `Wikifea` 上，较大的 `lambdaBIC` 对性能有益；而在 `Reuters-1200` 上，当 `lambdaBIC` 过大时，锚点数急剧下降并导致性能显著劣化，体现出典型的欠划分现象。`minNodeSize` 也呈现类似规律，过小会产生过多局部锚点，过大又会吞并有用的细粒度结构，因此中等范围通常更稳健。

相比之下，`lambda` 在当前搜索区间内的影响较为平缓，而 `beta` 在若干数据集上表现出更强敏感性。这说明当前方法的主要调参难点仍集中在锚点选择阶段，而不是跨视图对齐阶段。

### 10.5 运行效率分析

从当前结果看，`BIC-LR-3AMVC` 相比部分消融方法引入了额外的锚点生成与对齐开销，但该开销通常对应于更高的聚类质量。需要注意的是，现有结果文件中的 `anchorTime` 受到缓存命中状态影响，`algoTime` 又未与最终 KMeans 评价时间分离，因此这些时间结果更适合作定性比较而非严格复杂度结论。尽管如此，`w/o BIC` 与 `w/o LR` 在多个数据集上由于产生更多锚点或执行更多无效划分而呈现更高的总耗时，而 `w/o alignment` 虽然在部分数据集上节省了后续融合开销，却带来了明显的聚类性能损失。因此，从“性能-代价”平衡角度看，完整模型仍具有更高的综合价值。

### 10.6 局限性分析

当前方法仍存在若干限制。首先，`lambdaBIC` 与 `minNodeSize` 需要针对数据集进行搜索，尚未达到完全免调参。其次，BIC-LR 假设局部节点服从球形高斯分布，这一假设在高维异方差或强非球形结构数据上未必总是成立。再次，在高维小样本节点中，方差估计可能不稳定，即使引入了 `epsVar` 保护，也不能完全消除统计近似误差。最后，投影扫描候选切分点带来了一定计算负担，而当前结果尚未进行多 seed 完整管线稳定性验证，因此后续仍需补充更严格的随机性分析与更公平的原始 3AMVC 本地基线对照。

## 十一、建议生成的表格与图

### 11.1 建议表格

#### 表 1 主实验结果表
- 行：数据集
- 列：`Method, ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Runtime, AnchorNums, BaselineView`
- 建议方法：
  - `Original 3AMVC / HBNC-3AMVC`，若后续补齐本地结果
  - `BIC-LR-3AMVC`
- 作用：
  - 展示主方法整体性能。
  - 若暂时没有本地 Original 3AMVC 结果，可先只放 `BIC-LR-3AMVC`，并在正文说明基线待补。

#### 表 2 三类消融实验表
- 行：数据集
- 列：`BIC-LR-3AMVC, w/o BIC, w/o LR, w/o alignment`
- 每个单元格建议写 `ACC / NMI / Fscore` 或写成三行子表。
- 作用：
  - 直接支撑三个模块必要性的消融结论。

#### 表 3 每视图锚点数量表
- 行：数据集与方法
- 列：`View1Anchors, View2Anchors, ..., MeanAnchors, StdAnchors, BaselineView`
- 作用：
  - 说明不同视图允许不同锚点数。
  - 展示 `w/o BIC` 和 `w/o LR` 是否导致锚点膨胀。

#### 表 4 Runtime 对比表
- 行：数据集与方法
- 列：`AnchorTime, AlgoTime, TotalTime, CacheHit`
- 作用：
  - 解释锚点生成和整体开销。
  - 必须在表注中注明：`AlgoTime` 含 `myNMIACCwithmean`，`AnchorTime` 受缓存影响。

### 11.2 建议图形

#### 图 1 三类消融柱状图
- 横轴：数据集
- 纵轴：`ACC`
- 图例：`BIC-LR-3AMVC, w/o BIC, w/o LR, w/o alignment`
- 作用：
  - 最直观看出三类消融的性能差距。

#### 图 2 锚点总数对比图
- 横轴：数据集
- 纵轴：`AnchorTotal`
- 图例：`BIC-LR-3AMVC, w/o BIC, w/o LR, w/o alignment`
- 作用：
  - 直观看出 `w/o BIC` 是否导致锚点激增。

#### 图 3 参数敏感性曲线
- 前提：只对完整模型作图
- 横轴：`lambdaBIC` 或 `minNodeSize`
- 左纵轴：`ACC`
- 右纵轴：`AnchorTotal`
- 每个数据集各画一张或合并为子图
- 作用：
  - 展示复杂度控制与性能之间的折中。

#### 图 4 视图质量与基准视图示意图
- 横轴：视图编号
- 纵轴：`anchorQuality`
- 不同颜色标出被选中的 `BaselineView`
- 作用：
  - 直观说明“质量最优视图作为基准视图”的机制。

#### 图 5 稳定性箱线图
- 仅当后续补齐多 seed 完整管线结果时再制作
- 横轴：方法
- 纵轴：`ACC` 或 `NMI`
- 作用：
  - 展示随机性稳定性

## 十二、仍需补充的信息

### 12.1 当前缺失且影响论文严谨性的内容

- 缺少本地 `Original 3AMVC / HBNC-3AMVC` 独立结果文件。
- 缺少与主模型同评价协议的本地原始基线对照。
- 缺少多 seed 完整管线稳定性结果。
- 缺少三类消融实验的参数敏感性专门结果。
- 缺少运行环境记录，如 MATLAB 版本、CPU、内存。
- 缺少单独的 KMeans 评价耗时字段。

### 12.2 当前结果解释时必须保留的限制

- 完整模型使用 refined 结果，三类消融仅完成 coarse 结果，重复次数不完全一致。
- 所有最优配置均按 `best ACC` 选择，因此个别数据集可能出现 `ACC` 与 `NMI/Purity` 趋势不一致。
- 部分运行时间结果受缓存命中状态影响，不能直接视为完全公平的复杂度比较。
- 原论文 `w/o alignment` 的定义与当前仓库实现不完全相同，因此只能作趋势性讨论。

### 12.3 当前可以稳妥写出的核心结论

- `BIC-LR-3AMVC` 在当前仓库结果中，相对三类已完成消融实验总体表现更优，尤其在 `w/o alignment` 上优势最明显。
- `w/o BIC` 和 `w/o LR` 的结果支持“合理的复杂度控制”和“统计化分裂判断”对锚点质量是有价值的。
- 当前结果支持“BIC-LR 改进增强了原 3AMVC 的单视图锚点选择阶段，但没有改变跨视图对齐与等权融合主线”的论文叙述。
- 若要形成完全闭环的主实验章节，仍需补齐本地 `Original 3AMVC/HBNC` 基线结果。
