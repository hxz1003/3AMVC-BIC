# BIC-LR-3AMVC 消融实验框架

本目录是独立于 `3AMVC-main` 的消融实验管理框架，位置为：

```text
D:\matlab\3AMVC-BIC\ablation_biclr
```

本框架只通过 `addpath` 复用 `3AMVC-main` 中的数据集、A0 代码、A0 结果和核心函数，不移动、不覆盖 `3AMVC-main` 下的已有结果。

## 已实现方法

| 方法 | 含义 | 关键设置 |
|---|---|---|
| `A0_Full_Reference` | 引用已有完整 BIC-LR-3AMVC 结果 | 默认不重跑 A0，只读取 `3AMVC-main` 下已有结果 |
| `A1_woBIC_Joint` | 去掉 BIC 惩罚的联合消融 | `lambdaBIC=0`，目标视图质量字段为 `LRUnitEvidence`，保留多视图融合 |
| `A3_SSETarget` | 去掉 BIC 视图选择 | 锚点生成保持 BIC-LR，仅将目标视图改为 `SSEMin` |
| `A4_woMultiViewFusion` | 去掉多视图融合 | 只使用目标视图单视图锚图聚类，`lambda=NaN` |

本轮明确未实现：

```text
A2_woLR_OriginalHBNC_Bridge
A2b_HBNC_BICViewSelect
A1b_woBICSplit
A5 lambdaBIC sensitivity
A6 minNodeSize sensitivity
A7 seed stability
A8 Matched Anchor Number Control
V1 Anchor Distribution Visualization
```

若调用 `A2_woLR_OriginalHBNC_Bridge`，框架会直接报错并说明 A2 将通过原始 3AMVC GitHub 代码和论文/补充材料结果处理。

## 支持数据集与别名

| 结果目录名 | 真实数据文件 | 支持别名 |
|---|---|---|
| `Mfeat` | `MFeat_2Views.mat` | `Mfeat`, `MFeat`, `mfeat` |
| `Ruter1200` | `Reuters-1200.mat` | `Ruter-1200`, `Ruter1200`, `Reuters-1200`, `Reuters1200`, `Reuters` |
| `WIKI` | `Wikifea.mat` | `WIKI`, `Wiki`, `wiki` |
| `Catlch101All` | `Caltech101-all.mat` | `catlch101 all`, `Catlch101All`, `Caltech101-all`, `Caltech101_all`, `Caltech101` |
| `ForestTypes` | `ForestTypes.mat` | `ForestTypes`, `ForestType`, `Forest` |
| `Caltech256_4Views_257cls_withClutter` | `Caltech256_4Views_257cls_withClutter.mat` | `Caltech256_4Views_257cls_withClutter`, `Caltech256_withClutter`, `Caltech256` |

数据集缺失时，`run_one_biclr_ablation` 会打印已查找的完整路径，并提示应放入 `3AMVC-main/dataset`。

## 随机种子

已从 `3AMVC-main` 的 A0 相关脚本中定位到默认 `randomSeed/baseSeed = 1`，因此本框架默认：

```matlab
config.seeds = 1;
```

随机种子会写入：

- `result.randomSeed`
- `resultSummary.selectedConfig.randomSeed`
- 锚点缓存键
- 结果文件中的 `config.seeds`

若后续需要多 seed 统计，请修改：

```text
ablation_biclr/configs/common/get_default_grid_config.m
```

## 网格来源

默认优先调用：

```text
3AMVC-main/build_biclr_refined_config.m
```

获取 A0 已有精细网格。若该函数不可用，则使用 `get_dataset_grid_config.m` 中的兼容默认网格，并在 `config.gridSource` 中记录来源。

`Catlch101All` 默认收缩为单点 smoke 网格，只有设置：

```matlab
config.enableLargeDataset = true;
```

或通过 suite 的 `options.enableLargeDataset = true`，才启用完整网格。

`Caltech256_4Views_257cls_withClutter` 不再使用 256 组完整精细网格作为消融默认值。框架会根据已有 Caltech256 日志中 `beta=200, lambda=1000, lambdaBIC=3, minNodeSize=120` 附近的最优区域，为不同消融方法设置约 40 组网格：

| 方法 | 默认组合数 | 网格说明 |
|---|---:|---|
| `A1_woBIC_Joint` | 36 | `lambdaBIC=0`，搜索 `beta/lambda/minNodeSize` |
| `A3_SSETarget` | 48 | 保留 BIC-LR 锚点生成，搜索 A0 最优附近的 `beta/lambda/lambdaBIC/minNodeSize` |
| `A4_woMultiViewFusion` | 36 | `lambda=NaN`，搜索 `beta/lambdaBIC/minNodeSize` |

## 单脚本运行示例

```matlab
run('D:\matlab\3AMVC-BIC\ablation_biclr\scripts\A1_woBIC_Joint\run_A1_Mfeat_grid.m')
run('D:\matlab\3AMVC-BIC\ablation_biclr\scripts\A3_SSETarget\run_A3_ForestTypes_grid.m')
run('D:\matlab\3AMVC-BIC\ablation_biclr\scripts\A4_woMultiViewFusion\run_A4_Caltech256_grid.m')
```

每个脚本会：

1. 自动定位 `repoRoot`、`3AMVC-main` 和 `ablation_biclr`。
2. 自动 `addpath(genpath(...))`。
3. 设置 `methodName` 和 `datasetName`。
4. 读取默认配置、数据集配置和方法配置。
5. 调用 `run_one_biclr_ablation(methodName, datasetName, config)`。
6. 将结果保存到 `ablation_biclr/res/{methodName}/{datasetResultName}/`。

## 批量运行示例

默认批量运行 `A1/A3/A4` 在 `Mfeat/Ruter1200/WIKI/ForestTypes` 上的实验：

```matlab
summaries = run_ablation_biclr_suite();
```

只跑一个方法：

```matlab
options = struct();
options.methodName = 'A3_SSETarget';
summaries = run_ablation_biclr_suite(options);
```

只跑一个数据集并使用 smokeTest：

```matlab
options = struct();
options.datasetName = 'Mfeat';
options.smokeTest = true;
summaries = run_ablation_biclr_suite(options);
```

允许大型数据集完整网格：

```matlab
options = struct();
options.enableLargeDataset = true;
summaries = run_ablation_biclr_suite(options);
```

## 结果保存

每次运行保存到：

```text
ablation_biclr/res/{methodName}/{datasetResultName}/
```

文件格式：

```text
{methodName}_{datasetResultName}_grid_{yyyyMMdd_HHmmss}.mat
{methodName}_{datasetResultName}_latest.mat
```

每个 `.mat` 至少包含：

```text
allResults
resultSummary
config
methodConfig
datasetInfo
timestamp
repoRoot
mainCodeRoot
ablationRoot
```

## 汇总结果

运行：

```matlab
summaryTables = summarize_ablation_results();
```

输出：

```text
ablation_biclr/reports/main_tables/
ablation_biclr/reports/mechanism/
ablation_biclr/reports/view_selection/
```

包括主性能表、机制分析表、搜索预算表和 A3 视图选择分析表。

## 注意事项

- A0 引用脚本只读取已有结果；若找不到结果，会 warning 并保存空引用摘要，不会让整个框架崩溃。
- A1 不复用 A0 的非零 `lambdaBIC` 锚点缓存。
- A3/A4 优先读取 A0 锚点缓存；若找不到，生成后写入各自的 ablation 缓存。
- A4 不做未对齐锚图平均，只使用目标视图的单视图锚图聚类。
- 本框架不修改 `3AMVC-main` 原始文件。
