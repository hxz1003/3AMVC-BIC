# BIC-LR-3AMVC fixed-parameter strict ablation 说明

## 1. 严格消融目的

本目录中的脚本用于执行 fixed-parameter strict ablation。每个数据集先从 `3AMVC-main/res_biclr_refined` 读取 A0 best 配置，然后固定 A0 的 `beta`、`lambda`、`lambdaBIC`、`minNodeSize`、`numRuns`、`randomSeed`、数据集路径和工程参数，只改变一个模块。

该实验用于补充当前已有的混合口径报告和各变体各自最优网格结果，避免把搜索空间差异误解释为单一模块贡献。

## 2. 与已有网格消融的区别

已有 `ablation_biclr/res` 中的 A1/A3/A4 是各变体在各自网格中选出的最优结果，适合观察变体可达到的性能，但不是严格单变量消融。

本目录脚本不执行 grid search，`numGridConfigs=1`，`searchBudget=numRuns`。除指定模块外，其余参数都保持 A0 best 配置不变。

## 3. 三个严格消融只改变什么

- `A1_fixed_woBIC`：只关闭 BIC 复杂度惩罚。当前代码没有独立 `useBICPenalty` 开关，因此通过 `lambdaBIC=0` 实现；目标视图选择规则保持 A0 的 `BICUnitEvidence` 口径。
- `A3_fixed_SSETarget`：只把目标视图选择准则从 `BICUnitEvidence` 改为 `SSEMin`。锚点生成参数仍使用 A0 best，脚本同时保存 `A0_targetView`、`BIC_targetView` 和 `SSE_targetView`。
- `A4_fixed_woMultiViewFusion`：只关闭多视图对齐融合，使用目标视图单视图锚图进行最终聚类。`lambda` 会保存为 A0 best 值，但记录 `lambdaNotUsed=true`，`alignmentTime=0`。

## 4. 每个脚本如何运行

在 MATLAB 中进入本目录或将本目录加入路径后运行单个脚本，例如：

```matlab
run_A1_fixed_woBIC_Mfeat
run_A3_fixed_SSETarget_Reuters1200
run_A4_fixed_woMultiViewFusion_Caltech256
```

也可以运行总控脚本：

```matlab
run_all_strict_fixed_ablation
run_all_strict_fixed_ablation('A1_fixed_woBIC')
run_all_strict_fixed_ablation('A4_fixed_woMultiViewFusion', 'WIKI')
run_all_strict_fixed_ablation({'A1_fixed_woBIC','A3_fixed_SSETarget'}, {'Mfeat','Reuters-1200'})
```

总控脚本会在每次运行前打印当前 `dataset`、`method` 和 fixedConfig 摘要；若某个数据集报错，会写入错误日志并继续下一个任务。

## 5. 结果保存位置

结果只保存到新目录：

```text
ablation_biclr/res_strict_fixed
```

每次运行会生成带时间戳的 `.mat` 和 `.txt` 摘要，不覆盖 `ablation_biclr/res` 中已有结果。若任务报错，错误文件保存到：

```text
ablation_biclr/res_strict_fixed/_errors
```

## 6. 如何生成后续报告

严格消融运行完成后，可读取 `res_strict_fixed/<method>/<dataset>` 下最新 `.mat` 文件，按 `result.ACC_mean`、`result.NMI_mean`、`result.AR_mean` 与 A0 best 或 A0 fixed rerun 对比。

建议后续报告至少列出：

- `result.fixedConfig`
- `result.changedOnly`
- `result.ACC_mean / NMI_mean / AR_mean`
- `result.ACC_std / NMI_std / AR_std`
- `result.anchorCounts / avgAnchors`
- `result.targetView / A0_targetView / BIC_targetView / SSE_targetView`
- `result.acceptedSplits / rejectedSplits / meanLeafSize / maxDepth`
- `result.anchorTime / alignmentTime / totalTime`

## 7. 注意事项

- 不要重新搜索参数。
- 不要覆盖已有 `ablation_biclr/res`。
- Caltech256 数据版本是 257 类含 clutter，本地 baseline 与原论文 baseline 不完全一致。
- 若 A0 best 文件字段缺失，脚本会在本目录生成 `config_missing_report.md`，并提示需要人工从日志或已有 summary 中补全。
- 脚本会优先只读复用已有锚点缓存；若找不到匹配缓存，会在内存中重新生成锚点，但不会向旧缓存目录写入新缓存。
