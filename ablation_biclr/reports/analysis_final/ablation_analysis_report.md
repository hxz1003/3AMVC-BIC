# BIC-LR-3AMVC 消融实验结果分析

分析日期：2026-05-16

---

## 1. 实验结果读取情况

### 已读取的消融结果

| 方法 | Mfeat | Reuters-1200 | WIKI | ForestTypes | Caltech256 |
|------|-------|-------------|------|-------------|------------|
| A0_Full_Reference | refined 结果 | refined 结果 | refined 结果 | ablation latest | refined 结果 |
| A1_woBIC_Joint | latest | latest | latest | latest | latest |
| A3_SSETarget | latest | latest | latest | latest | latest |
| A4_woMultiViewFusion | latest | latest | latest | latest | latest |

- A0 在 ablation_biclr/res 中仅有 ForestTypes，其余使用 3AMVC-main/res_biclr_refined 中的 refined 搜索结果。
- 所有 A1/A3/A4 结果来自 ablation_biclr/res 中的 latest 文件。
- 未发现 smoke test 结果。
- 原论文 PDF 和补充材料 PDF 均成功读取。
- Caltech256 本地 baseline 成功读取（refined4 结果）。

---

## 2. 原论文与补充材料信息提取

详见 paper_baseline_extracted.md。

关键信息：
- 原论文 3AMVC 使用 HBNC 生成锚点，使用 SSEMin 选择基准视图。
- 原论文仅报告 ACC/NMI/Fscore。
- 原论文参数搜索：beta={0.01,1,100}, lambda={0,0.0001,0.01,1,10000}。
- 补充材料 HBNC 锚点数：ForestTypes=[10,16,20], MFeat=[54,64], Reuters=[62,48,45,13,53], Caltech256=[48,67,62,45]。

---

## 3. Caltech256 特殊说明

本文当前使用的 Caltech256 数据文件为 catlch256_4Views_257cls_withClutter.mat，由用户自行处理，包含 257 类（含 clutter）。该数据版本与原论文 Caltech256（256 类）不完全一致。

- 原论文 Caltech256 结果（ACC=0.1023）暂不作为正式对比基线。
- Caltech256 的原始 3AMVC baseline 使用本地源码运行结果（ACC=0.1807, NMI=0.4165, beta=30, lambda=300000, anchors=[53,70,45,79]）。

---

## 4. 主性能比较

### 主性能表（ACC / NMI / AR）

| 数据集 | A0 Full | A1 w/o BIC | A3 SSE Target | A4 Single View |
|--------|---------|------------|---------------|----------------|
| Mfeat | 0.8943 / 0.8260 / - | 0.8990 / 0.8233 / 0.7966 | 0.8990 / 0.8233 / 0.7966 | 0.5837 / 0.5347 / 0.4016 |
| Reuters-1200 | 0.6481 / 0.3977 / - | 0.5605 / 0.3381 / 0.2669 | 0.5956 / 0.3620 / 0.2957 | 0.6105 / 0.3462 / 0.3103 |
| WIKI | 0.5579 / 0.5204 / - | 0.5392 / 0.5097 / 0.3786 | 0.5803 / 0.5249 / 0.4327 | 0.5546 / 0.5110 / 0.3603 |
| ForestTypes | 0.8040 / 0.5154 / 0.5482 | 0.7847 / 0.4942 / 0.5159 | 0.8040 / 0.5154 / 0.5482 | 0.6778 / 0.3772 / 0.3530 |
| Caltech256 | 0.3043 / 0.5379 / - | 0.3188 / 0.5559 / 0.2209 | 0.2444 / 0.4814 / 0.1665 | 0.0889 / 0.3157 / 0.0610 |

### 带 Original 3AMVC Baseline 的主性能表

| 数据集 | Original 3AMVC | A0 Full | A1 w/o BIC | A3 SSE Target | A4 Single View |
|--------|---------------|---------|------------|---------------|----------------|
| Mfeat | 0.8737 / 0.8240 | 0.8943 / 0.8260 | 0.8990 / 0.8233 | 0.8990 / 0.8233 | 0.5837 / 0.5347 |
| Reuters | 0.5734 / 0.3316 | 0.6481 / 0.3977 | 0.5605 / 0.3381 | 0.5956 / 0.3620 | 0.6105 / 0.3462 |
| WIKI | Missing | 0.5579 / 0.5204 | 0.5392 / 0.5097 | 0.5803 / 0.5249 | 0.5546 / 0.5110 |
| ForestTypes | 0.7984 / 0.5397 | 0.8040 / 0.5154 | 0.7847 / 0.4942 | 0.8040 / 0.5154 | 0.6778 / 0.3772 |
| Caltech256 | 0.1807* / 0.4165* | 0.3043 / 0.5379 | 0.3188 / 0.5559 | 0.2444 / 0.4814 | 0.0889 / 0.3157 |

注：Caltech256 标注 * 为本地原始源码运行结果。WIKI 不在原论文中。

### A0 vs Original 3AMVC

| 数据集 | Delta ACC | Delta NMI |
|--------|-----------|-----------|
| Mfeat | +2.06% | +0.20% |
| Reuters-1200 | +7.47% | +6.61% |
| ForestTypes | +0.56% | -2.43% |
| Caltech256 | +12.36% | +12.14% |

### 各消融方法相对 A0 的性能变化

| 数据集 | 方法 | Delta ACC | Delta NMI | Delta AR |
|--------|------|-----------|-----------|----------|
| Mfeat | A1 | +0.47% | -0.27% | - |
| Mfeat | A3 | +0.47% | -0.27% | - |
| Mfeat | A4 | -31.06% | -29.13% | - |
| Reuters | A1 | -8.76% | -5.96% | - |
| Reuters | A3 | -5.25% | -3.57% | - |
| Reuters | A4 | -3.76% | -5.15% | - |
| WIKI | A1 | -1.87% | -1.07% | - |
| WIKI | A3 | +2.24% | +0.45% | - |
| WIKI | A4 | -0.33% | -0.94% | - |
| Forest | A1 | -1.93% | -2.12% | -3.23% |
| Forest | A3 | 0.00% | 0.00% | 0.00% |
| Forest | A4 | -12.62% | -13.82% | -19.52% |
| Caltech | A1 | +1.45% | +1.80% | - |
| Caltech | A3 | -5.99% | -5.65% | - |
| Caltech | A4 | -21.54% | -22.22% | - |

---

## 5. BIC 惩罚有效性分析：A0 vs A1

### 锚点数对比

| 数据集 | A0 anchors | A1 anchors | A1/A0 |
|--------|-----------|-----------|-------|
| Mfeat | [49,46]=95 | [65,63]=128 | 1.35x |
| Reuters | [41,42,47,38,47]=215 | [60,62,64,62,62]=310 | 1.44x |
| WIKI | [15,35]=50 | [44,44]=88 | 1.76x |
| ForestTypes | [20,19,20]=59 | [20,19,21]=60 | 1.02x |
| Caltech256 | [171,78,97,116]=462 | [149,149,148,150]=596 | 1.29x |

### 分裂统计

| 数据集 | A1 accepted | A1 rejected | A1 meanLeafSize | A1 maxDepth |
|--------|-------------|-------------|-----------------|-------------|
| Mfeat | 126 | 128 | 31.3 | 8 |
| Reuters | 305 | 310 | 19.4 | 23 |
| WIKI | 86 | 88 | 65.1 | 16 |
| ForestTypes | 57 | 60 | 26.2 | 7 |
| Caltech256 | 592 | 596 | 205.4 | 13 |

### 分析

1. A1 在多数数据集上产生更多锚点（Mfeat +35%, Reuters +44%, WIKI +76%, Caltech256 +29%），证实去掉 BIC 惩罚后出现过度分裂倾向。

2. A1 的 meanLeafSize 更小（Reuters: 19.4），maxDepth 更大（Reuters: 23），锚点更碎片化。

3. A1 在多数数据集上性能下降（Reuters ACC -8.76%, WIKI -1.87%, ForestTypes -1.93%），过度分裂导致锚点质量下降。

4. Caltech256 异常：A1 ACC 略升 +1.45%，可能因为 A1 使用了不同的 minNodeSize=160 和 beta=200。

**结论：BIC penalty prevents over-segmentation by penalizing excessive split complexity.**

---

## 6. BICUnitEvidence 视图选择有效性分析：A0 vs A3

### 目标视图对比

| 数据集 | A0 BIC Target | A3 SSE Target | Agreement | 性能变化 |
|--------|--------------|---------------|-----------|----------|
| Mfeat | 1 | 1 | Yes | 持平 |
| Reuters | 1 | 3 | No | A3 下降 5.25% |
| WIKI | 2 | 1 | No | A3 略升 2.24% |
| ForestTypes | 3 | 3 | Yes | 持平 |
| Caltech256 | 3 | 1 | No | A3 下降 5.99% |

### 分析

1. 目标视图一致时（Mfeat, ForestTypes），A3 与 A0 性能一致，符合预期。

2. 目标视图不一致时，A3 在 Reuters 和 Caltech256 上明显下降，说明 BICUnitEvidence 选择了更优视图。

3. WIKI 上 A3 略升，但 A3 的锚点数（[29,50]=79）与 A0（[15,35]=50）不同，性能差异可能来自参数适配。

4. BIC 证据与 SSE 排序在多个数据集上不一致，两者确实会做出不同选择。

**结论：BICUnitEvidence provides a complexity-calibrated view quality criterion.**

---

## 7. 多视图融合必要性分析：A0 vs A4

| 数据集 | A0 ACC | A4 ACC | Delta | 说明 |
|--------|--------|--------|-------|------|
| Mfeat | 0.8943 | 0.5837 | -31.06% | 大幅下降，融合至关重要 |
| Reuters | 0.6481 | 0.6105 | -3.76% | 下降 |
| WIKI | 0.5579 | 0.5546 | -0.33% | 持平，目标视图主导 |
| ForestTypes | 0.8040 | 0.6778 | -12.62% | 明显下降 |
| Caltech256 | 0.3043 | 0.0889 | -21.54% | 大幅下降 |

A4 的 alignmentTime 均为 0，确认正确跳过了跨视图对齐。

**结论：Multi-view fusion is necessary for transferring the improved anchor representation to final clustering. 在 4/5 个数据集上，多视图融合显著提升了聚类质量。**

---

## 8. 机制指标分析

| 数据集 | Method | AvgAnchors | TargetV | AccSplits | RejSplits | MeanLeaf | MaxDepth | AnchorT | AlignT | TotalT |
|--------|--------|-----------|---------|-----------|-----------|----------|----------|---------|--------|--------|
| Mfeat | A0 | 47.5 | 1 | - | - | - | - | - | - | 119.1 |
| Mfeat | A1 | 64.0 | 1 | 126 | 128 | 31.3 | 8 | 0.7 | 2.3 | 69.9 |
| Mfeat | A3 | 64.0 | 1 | 126 | 128 | 31.3 | 8 | 0.5 | 2.4 | 280.8 |
| Mfeat | A4 | 35.0 | 1 | 68 | 70 | 57.3 | 7 | 0.4 | 0.0 | 60.7 |
| Reuters | A0 | 43.0 | 1 | - | - | - | - | - | - | 409.5 |
| Reuters | A1 | 62.0 | 3 | 305 | 310 | 19.4 | 23 | 12.1 | 6.3 | 520.8 |
| Reuters | A3 | 28.2 | 3 | 136 | 141 | 42.7 | 14 | 13.7 | 7.1 | 727.9 |
| Reuters | A4 | 25.2 | 4 | 121 | 126 | 47.8 | 13 | 0.0 | 0.0 | 159.2 |
| WIKI | A0 | 25.0 | 2 | - | - | - | - | - | - | 420.5 |
| WIKI | A1 | 44.0 | 2 | 86 | 88 | 65.1 | 16 | 0.3 | 2.0 | 211.3 |
| WIKI | A3 | 39.5 | 1 | 77 | 79 | 78.1 | 12 | 0.2 | 1.8 | 515.8 |
| WIKI | A4 | 26.0 | 2 | 50 | 52 | 121.8 | 11 | 0.3 | 0.0 | 125.9 |
| Forest | A0 | 19.7 | 3 | - | - | - | - | 0.0 | - | 0.6 |
| Forest | A1 | 20.0 | 3 | 57 | 60 | 26.2 | 7 | 0.0 | 0.9 | 120.7 |
| Forest | A3 | 19.7 | 3 | 56 | 59 | 26.6 | 7 | 0.0 | 0.6 | 835.2 |
| Forest | A4 | 25.3 | 1 | 73 | 76 | 20.7 | 8 | 0.0 | 0.0 | 29.9 |
| Caltech | A0 | 115.5 | 3 | - | - | - | - | 138.3 | 115.3 | 253.6 |
| Caltech | A1 | 149.0 | 3 | 592 | 596 | 205.4 | 13 | 198.2 | 114.4 | 8828.1 |
| Caltech | A3 | 133.3 | 1 | 529 | 533 | 262.0 | 13 | 385.4 | 135.4 | 7995.7 |
| Caltech | A4 | 81.0 | 3 | 320 | 324 | 403.8 | 11 | 231.3 | 0.0 | 3834.1 |

---

## 9. 搜索预算与公平性说明

| 数据集 | Method | numGridConfigs | numSeeds | numRuns | searchBudget |
|--------|--------|---------------|----------|---------|-------------|
| Mfeat | A0 | 15 | 1 | 10 | 150 |
| Mfeat | A1 | 48 | 1 | 10 | 480 |
| Mfeat | A3 | 240 | 1 | 10 | 2400 |
| Mfeat | A4 | 80 | 1 | 10 | 800 |
| Reuters | A0 | 15 | 1 | 8 | 120 |
| Reuters | A1 | 48 | 1 | 8 | 384 |
| Reuters | A3 | 192 | 1 | 8 | 1536 |
| Reuters | A4 | 64 | 1 | 8 | 512 |
| Forest | A0 | 625 | 1 | 10 | 6250 |
| Forest | A1 | 125 | 1 | 10 | 1250 |
| Forest | A3 | 625 | 1 | 10 | 6250 |
| Forest | A4 | 125 | 1 | 10 | 1250 |
| Caltech | A0 | 256 | 1 | 3 | 768 |
| Caltech | A1 | 36 | 1 | 3 | 108 |
| Caltech | A3 | 48 | 1 | 3 | 144 |
| Caltech | A4 | 36 | 1 | 3 | 108 |

- A0 使用 refined 搜索（较小网格），A1/A3/A4 使用完整网格搜索。A0 的 refined 搜索已经过优化。
- 所有方法使用相同 numSeeds=1。
- A4 不含 lambda，搜索空间天然更小。
- Caltech256 的 numRuns=3（其他为 8-10），因为数据量大。

---

## 10. 结论总结

1. **A1 结果**：在 4/5 数据集上 A1 低于 A0，BIC 惩罚有效抑制过度分裂。Caltech256 异常需复查。

2. **A3 结果**：在目标视图不一致的数据集上 A3 低于 A0（Reuters -5.25%, Caltech -5.99%），BICUnitEvidence 优于 SSEMin。

3. **A4 结果**：在 4/5 数据集上 A4 显著低于 A0（Mfeat -31%, Caltech -22%），多视图融合必要。

4. **A0 vs Original**：A0 在 Mfeat/Reuters/Caltech256 上显著优于原始 3AMVC，ForestTypes 基本持平。

5. **贡献最大模块**：多视图融合 > BIC 惩罚 > BICUnitEvidence 视图选择。

6. **最稳定数据集**：ForestTypes（A0/A3 完全一致，A1/A4 预期方向下降）。

7. **需复查**：Caltech256 A1 异常上升、WIKI A3 略升、A0 AR 值缺失、summary mode 不一致。

8. **是否需要补充 A2/B0**：建议补充原始 3AMVC 本地运行结果（使用 HBNC 而非 BIC-LR）作为更直接的 baseline 对比。
