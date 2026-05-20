# BIC-LR-3AMVC 消融实验分析：A0-best vs Ablation-mean

## 1. 实验结果读取情况
本报告读取 A0 完整模型在 `3AMVC-main/res_biclr_refined` 中的 best 结果，并读取 `ablation_biclr/res` 下 A1/A3/A4 的 latest 消融结果，消融组采用 mean 指标。

| Dataset | Method | SourceFile | Status |
| --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\MFeat_2Views_BICLR_refined_best_ACC.mat | Found |
| Mfeat | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Mfeat\A1_woBIC_Joint_Mfeat_latest.mat | Found |
| Mfeat | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Mfeat\A3_SSETarget_Mfeat_latest.mat | Found |
| Mfeat | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Mfeat\A4_woMultiViewFusion_Mfeat_latest.mat | Found |
| Reuters-1200 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Reuters_1200_BICLR_refined_best_ACC.mat | Found |
| Reuters-1200 | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Ruter1200\A1_woBIC_Joint_Ruter1200_latest.mat | Found |
| Reuters-1200 | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Ruter1200\A3_SSETarget_Ruter1200_latest.mat | Found |
| Reuters-1200 | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Ruter1200\A4_woMultiViewFusion_Ruter1200_latest.mat | Found |
| WIKI | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Wikifea_BICLR_refined_best_ACC.txt | Found |
| WIKI | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\WIKI\A1_woBIC_Joint_WIKI_latest.mat | Found |
| WIKI | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\WIKI\A3_SSETarget_WIKI_latest.mat | Found |
| WIKI | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\WIKI\A4_woMultiViewFusion_WIKI_latest.mat | Found |
| ForestTypes | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\ForestTypes_BICLR_refined_best_ACC.mat | Found |
| ForestTypes | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\ForestTypes\A1_woBIC_Joint_ForestTypes_latest.mat | Found |
| ForestTypes | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\ForestTypes\A3_SSETarget_ForestTypes_latest.mat | Found |
| ForestTypes | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\ForestTypes\A4_woMultiViewFusion_ForestTypes_latest.mat | Found |
| Caltech256 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt | Found |
| Caltech256 | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Caltech256_4Views_257cls_withClutter\A1_woBIC_Joint_Caltech256_4Views_257cls_withClutter_latest.mat | Found |
| Caltech256 | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Caltech256_4Views_257cls_withClutter\A3_SSETarget_Caltech256_4Views_257cls_withClutter_latest.mat | Found |
| Caltech256 | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Caltech256_4Views_257cls_withClutter\A4_woMultiViewFusion_Caltech256_4Views_257cls_withClutter_latest.mat | Found |

覆盖数据集：Mfeat、Reuters-1200、WIKI、ForestTypes、Caltech256；方法：A0_Full_Reference、A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion。未发现目标方法或目标数据集缺失。

A0 旧结果中 acceptedSplits、rejectedSplits、meanLeafSize、maxDepth、alignmentTime 等机制字段并不完整，因此机制分析主要依赖 A1/A3/A4 的统一结果字段。

## 2. 对比口径说明
- A0_Full_Reference 使用 `res_biclr_refined` 中的 best 值。
- A1_woBIC_Joint、A3_SSETarget、A4_woMultiViewFusion 使用各自 latest 结果中的 mean 值。
- 该结果不是严格同口径比较；它主要用于观察完整模型最优潜力与各消融变体平均性能之间的差异。
- 不能直接写成严格单变量消融结论；严格因果归因需要固定 A0 最优参数后只改变一个模块重新运行。

## 3. 主性能表
| Dataset | A0-best | A1-mean | A3-mean | A4-mean |
| --- | --- | --- | --- | --- |
| Mfeat | 0.9270 / 0.8540 / 0.8452 | 0.8990 / 0.8233 / 0.7966 | 0.8990 / 0.8233 / 0.7966 | 0.5837 / 0.5347 / 0.4016 |
| Reuters-1200 | 0.6592 / 0.4118 / 0.3748 | 0.5605 / 0.3381 / 0.2669 | 0.5956 / 0.3620 / 0.2957 | 0.6105 / 0.3462 / 0.3103 |
| WIKI | 0.5820 / 0.5133 / Missing | 0.5392 / 0.5097 / 0.3786 | 0.5803 / 0.5249 / 0.4327 | 0.5546 / 0.5110 / 0.3603 |
| ForestTypes | 0.8184 / 0.5530 / 0.5677 | 0.7847 / 0.4942 / 0.5159 | 0.8040 / 0.5154 / 0.5482 | 0.6778 / 0.3772 / 0.3530 |
| Caltech256 | 0.3043 / 0.5379 / Missing | 0.3188 / 0.5559 / 0.2209 | 0.2444 / 0.4814 / 0.1665 | 0.0889 / 0.3157 / 0.0610 |

## 4. 相对 A0-best 的差值表
| Dataset | Method | Delta ACC | Delta NMI | Delta AR |
| --- | --- | --- | --- | --- |
| Mfeat | A1_woBIC_Joint | -0.0280 | -0.0307 | -0.0486 |
| Mfeat | A3_SSETarget | -0.0280 | -0.0307 | -0.0486 |
| Mfeat | A4_woMultiViewFusion | -0.3433 | -0.3193 | -0.4437 |
| Reuters-1200 | A1_woBIC_Joint | -0.0986 | -0.0738 | -0.1079 |
| Reuters-1200 | A3_SSETarget | -0.0635 | -0.0499 | -0.0791 |
| Reuters-1200 | A4_woMultiViewFusion | -0.0486 | -0.0656 | -0.0645 |
| WIKI | A1_woBIC_Joint | -0.0428 | -0.0036 | Missing |
| WIKI | A3_SSETarget | -0.0017 | +0.0117 | Missing |
| WIKI | A4_woMultiViewFusion | -0.0274 | -0.0023 | Missing |
| ForestTypes | A1_woBIC_Joint | -0.0337 | -0.0589 | -0.0517 |
| ForestTypes | A3_SSETarget | -0.0143 | -0.0377 | -0.0195 |
| ForestTypes | A4_woMultiViewFusion | -0.1405 | -0.1759 | -0.2147 |
| Caltech256 | A1_woBIC_Joint | +0.0145 | +0.0180 | Missing |
| Caltech256 | A3_SSETarget | -0.0599 | -0.0565 | Missing |
| Caltech256 | A4_woMultiViewFusion | -0.2154 | -0.2222 | Missing |

## 5. A0-best 与 Original 3AMVC baseline 的比较
Mfeat、Reuters-1200 和 ForestTypes 使用原论文报告的 Original 3AMVC 结果；WIKI 未在原论文 baseline 中找到可比记录，标注为 Missing。Caltech256 使用本地原始源码 baseline，不直接采用原论文 Caltech256 指标，因为当前数据是用户自行处理的 257 类含 clutter 版本。

| Dataset | Original 3AMVC baseline | A0-best | Delta ACC | Delta NMI | Delta AR | Note |
| --- | --- | --- | --- | --- | --- | --- |
| Mfeat | 0.8737 / 0.8240 / Missing | 0.9270 / 0.8540 / 0.8452 | +0.0533 | +0.0300 | Missing | 使用原论文报告的 Original 3AMVC 指标；WIKI 若缺失则不比较。 |
| Reuters-1200 | 0.5734 / 0.3316 / Missing | 0.6592 / 0.4118 / 0.3748 | +0.0858 | +0.0802 | Missing | 使用原论文报告的 Original 3AMVC 指标；WIKI 若缺失则不比较。 |
| WIKI | Missing | 0.5820 / 0.5133 / Missing | Missing | Missing | Missing | 原论文或本地 baseline 中未找到该数据集。 |
| ForestTypes | 0.7984 / 0.5397 / Missing | 0.8184 / 0.5530 / 0.5677 | +0.0200 | +0.0133 | Missing | 使用原论文报告的 Original 3AMVC 指标；WIKI 若缺失则不比较。 |
| Caltech256 | 0.1807 / 0.4165 / 0.1121 | 0.3043 / 0.5379 / Missing | +0.1236 | +0.1214 | Missing | 使用本地原始源码 baseline；当前 Caltech256 为 257 类含 clutter 版本，不直接采用原论文 Caltech256 指标。 |

## 6. A1 w/o BIC 分析
- Mfeat：A1_woBIC_Joint 的 ACC/NMI/AR=0.8990 / 0.8233 / 0.7966，相对 A0-best 的差值为 ACC=-0.0280，NMI=-0.0307，AR=-0.0486；AvgAnchors=64，anchorCounts=[65 63]，targetView=1，acceptedSplits=[64 62]，meanLeafSize=[30.7692307692308 31.7460317460317]。
- Reuters-1200：A1_woBIC_Joint 的 ACC/NMI/AR=0.5605 / 0.3381 / 0.2669，相对 A0-best 的差值为 ACC=-0.0986，NMI=-0.0738，AR=-0.1079；AvgAnchors=62，anchorCounts=[60 62 64 62 62]，targetView=3，acceptedSplits=[59 61 63 61 61]，meanLeafSize=[20 19.3548387096774 18.75 19.3548387096774 19.3548387096774]。
- WIKI：A1_woBIC_Joint 的 ACC/NMI/AR=0.5392 / 0.5097 / 0.3786，相对 A0-best 的差值为 ACC=-0.0428，NMI=-0.0036，AR=Missing；AvgAnchors=44，anchorCounts=[44 44]，targetView=2，acceptedSplits=[43 43]，meanLeafSize=[65.1363636363636 65.1363636363636]。
- ForestTypes：A1_woBIC_Joint 的 ACC/NMI/AR=0.7847 / 0.4942 / 0.5159，相对 A0-best 的差值为 ACC=-0.0337，NMI=-0.0589，AR=-0.0517；AvgAnchors=20，anchorCounts=[20 19 21]，targetView=3，acceptedSplits=[19 18 20]，meanLeafSize=[26.15 27.5263157894737 24.9047619047619]。
- Caltech256：A1_woBIC_Joint 的 ACC/NMI/AR=0.3188 / 0.5559 / 0.2209，相对 A0-best 的差值为 ACC=+0.0145，NMI=+0.0180，AR=Missing；AvgAnchors=149，anchorCounts=[149 149 148 150]，targetView=3，acceptedSplits=[148 148 147 149]，meanLeafSize=[205.41610738255 205.41610738255 206.804054054054 204.046666666667]。
A1 去掉 BIC 复杂度惩罚后，若锚点数和 acceptedSplits 增加而性能下降，可视为过分裂风险的迹象。但由于这里是 A0-best vs A1-mean，A1 低于 A0 不一定全部来自 BIC 模块，口径差异和搜索空间差异也会影响数值。

## 7. A3 SSE Target 分析
- Mfeat：A3_SSETarget 的 ACC/NMI/AR=0.8990 / 0.8233 / 0.7966，相对 A0-best 的差值为 ACC=-0.0280，NMI=-0.0307，AR=-0.0486；AvgAnchors=64，anchorCounts=[65 63]，targetView=1，acceptedSplits=[64 62]，meanLeafSize=[30.7692307692308 31.7460317460317]。
- Reuters-1200：A3_SSETarget 的 ACC/NMI/AR=0.5956 / 0.3620 / 0.2957，相对 A0-best 的差值为 ACC=-0.0635，NMI=-0.0499，AR=-0.0791；AvgAnchors=28.2，anchorCounts=[30 28 30 26 27]，targetView=3，acceptedSplits=[29 27 29 25 26]，meanLeafSize=[40 42.8571428571429 40 46.1538461538462 44.4444444444444]。
- WIKI：A3_SSETarget 的 ACC/NMI/AR=0.5803 / 0.5249 / 0.4327，相对 A0-best 的差值为 ACC=-0.0017，NMI=+0.0117，AR=Missing；AvgAnchors=39.5，anchorCounts=[29 50]，targetView=1，acceptedSplits=[28 49]，meanLeafSize=[98.8275862068966 57.32]。
- ForestTypes：A3_SSETarget 的 ACC/NMI/AR=0.8040 / 0.5154 / 0.5482，相对 A0-best 的差值为 ACC=-0.0143，NMI=-0.0377，AR=-0.0195；AvgAnchors=19.6667，anchorCounts=[20 19 20]，targetView=3，acceptedSplits=[19 18 19]，meanLeafSize=[26.15 27.5263157894737 26.15]。
- Caltech256：A3_SSETarget 的 ACC/NMI/AR=0.2444 / 0.4814 / 0.1665，相对 A0-best 的差值为 ACC=-0.0599，NMI=-0.0565，AR=Missing；AvgAnchors=133.25，anchorCounts=[213 80 102 138]，targetView=1，acceptedSplits=[212 79 101 137]，meanLeafSize=[143.694835680751 382.5875 300.06862745098 221.789855072464]。
A3 将目标视图选择从 BICUnitEvidence 换成 SSEMin。若 targetView 改变且性能下降，可以说明 BICUnitEvidence 在该数据集上更有利；若 A3 接近或高于 A0，则说明目标视图选择具有数据集依赖性，不能写成 BICUnitEvidence 在所有数据集上必然优于 SSEMin。

## 8. A4 w/o Multi-view Fusion 分析
- Mfeat：A4_woMultiViewFusion 的 ACC/NMI/AR=0.5837 / 0.5347 / 0.4016，相对 A0-best 的差值为 ACC=-0.3433，NMI=-0.3193，AR=-0.4437；AvgAnchors=35，anchorCounts=[33 37]，targetView=1，acceptedSplits=[32 36]，meanLeafSize=[60.6060606060606 54.0540540540541]。
- Reuters-1200：A4_woMultiViewFusion 的 ACC/NMI/AR=0.6105 / 0.3462 / 0.3103，相对 A0-best 的差值为 ACC=-0.0486，NMI=-0.0656，AR=-0.0645；AvgAnchors=25.2，anchorCounts=[27 24 27 23 25]，targetView=4，acceptedSplits=[26 23 26 22 24]，meanLeafSize=[44.4444444444444 50 44.4444444444444 52.1739130434783 48]。
- WIKI：A4_woMultiViewFusion 的 ACC/NMI/AR=0.5546 / 0.5110 / 0.3603，相对 A0-best 的差值为 ACC=-0.0274，NMI=-0.0023，AR=Missing；AvgAnchors=26，anchorCounts=[18 34]，targetView=2，acceptedSplits=[17 33]，meanLeafSize=[159.222222222222 84.2941176470588]。
- ForestTypes：A4_woMultiViewFusion 的 ACC/NMI/AR=0.6778 / 0.3772 / 0.3530，相对 A0-best 的差值为 ACC=-0.1405，NMI=-0.1759，AR=-0.2147；AvgAnchors=25.3333，anchorCounts=[25 26 25]，targetView=1，acceptedSplits=[24 25 24]，meanLeafSize=[20.92 20.1153846153846 20.92]。
- Caltech256：A4_woMultiViewFusion 的 ACC/NMI/AR=0.0889 / 0.3157 / 0.0610，相对 A0-best 的差值为 ACC=-0.2154，NMI=-0.2222，AR=Missing；AvgAnchors=81，anchorCounts=[116 59 66 83]，targetView=3，acceptedSplits=[115 58 65 82]，meanLeafSize=[263.853448275862 518.762711864407 463.742424242424 368.759036144578]。
A4 去掉跨视图对齐融合，只使用目标视图锚图进行最终聚类。该组通常是最稳定、最强的模块证据：若 ACC/NMI/AR 明显下降，说明多视图对齐融合对最终表示有关键贡献。WIKI 的下降较小，可能说明其目标视图本身已经较强。

## 9. 机制指标分析
| Dataset | Method | ResultType | AvgAnchors | AnchorCounts | TargetView | AcceptedSplits | RejectedSplits | MeanLeafSize | MaxDepth | AnchorTime | AlignmentTime | TotalTime |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | best | 47.5 | [49;46] | 1 | Missing | Missing | Missing | Missing | Missing | Missing | 119.047 |
| Mfeat | A1_woBIC_Joint | mean | 64 | [65 63] | 1 | [64 62] | [65 63] | [30.7692307692308 31.7460317460317] | [8 7] | 0.675461 | 2.25684 | 69.8604 |
| Mfeat | A3_SSETarget | mean | 64 | [65 63] | 1 | [64 62] | [65 63] | [30.7692307692308 31.7460317460317] | [8 7] | 0.504116 | 2.38263 | 280.775 |
| Mfeat | A4_woMultiViewFusion | mean | 35 | [33 37] | 1 | [32 36] | [33 37] | [60.6060606060606 54.0540540540541] | [7 6] | 0.377688 | 0 | 60.6602 |
| Reuters-1200 | A0_Full_Reference | best | 43 | [41;42;47;38;47] | 1 | Missing | Missing | Missing | Missing | Missing | Missing | 409.531 |
| Reuters-1200 | A1_woBIC_Joint | mean | 62 | [60 62 64 62 62] | 3 | [59 61 63 61 61] | [60 62 64 62 62] | [20 19.3548387096774 18.75 19.3548387096774 19.3548387096774] | [22 17 21 19 23] | 12.1451 | 6.29486 | 520.79 |
| Reuters-1200 | A3_SSETarget | mean | 28.2 | [30 28 30 26 27] | 3 | [29 27 29 25 26] | [30 28 30 26 27] | [40 42.8571428571429 40 46.1538461538462 44.4444444444444] | [14 13 10 11 9] | 13.741 | 7.11859 | 727.91 |
| Reuters-1200 | A4_woMultiViewFusion | mean | 25.2 | [27 24 27 23 25] | 4 | [26 23 26 22 24] | [27 24 27 23 25] | [44.4444444444444 50 44.4444444444444 52.1739130434783 48] | [13 12 10 10 10] | 0 | 0 | 159.247 |
| WIKI | A0_Full_Reference | best | 25 | [15 35] | 2 | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| WIKI | A1_woBIC_Joint | mean | 44 | [44 44] | 2 | [43 43] | [44 44] | [65.1363636363636 65.1363636363636] | [9 16] | 0.263218 | 2.03868 | 211.328 |
| WIKI | A3_SSETarget | mean | 39.5 | [29 50] | 1 | [28 49] | [29 50] | [98.8275862068966 57.32] | [7 12] | 0.226296 | 1.75119 | 515.832 |
| WIKI | A4_woMultiViewFusion | mean | 26 | [18 34] | 2 | [17 33] | [18 34] | [159.222222222222 84.2941176470588] | [6 11] | 0.268523 | 0 | 125.942 |
| ForestTypes | A0_Full_Reference | best | 16.6667 | [17;17;16] | 3 | Missing | Missing | Missing | Missing | Missing | Missing | 522.453 |
| ForestTypes | A1_woBIC_Joint | mean | 20 | [20 19 21] | 3 | [19 18 20] | [20 19 21] | [26.15 27.5263157894737 24.9047619047619] | [7 7 7] | 0.0379221 | 0.923514 | 120.67 |
| ForestTypes | A3_SSETarget | mean | 19.6667 | [20 19 20] | 3 | [19 18 19] | [20 19 20] | [26.15 27.5263157894737 26.15] | [7 7 7] | 0 | 0.576996 | 835.194 |
| ForestTypes | A4_woMultiViewFusion | mean | 25.3333 | [25 26 25] | 1 | [24 25 24] | [25 26 25] | [20.92 20.1153846153846 20.92] | [8 8 8] | 0 | 0 | 29.9225 |
| Caltech256 | A0_Full_Reference | best | 115.5 | [171 78 97 116] | 3 | Missing | Missing | Missing | Missing | Missing | Missing | Missing |
| Caltech256 | A1_woBIC_Joint | mean | 149 | [149 149 148 150] | 3 | [148 148 147 149] | [149 149 148 150] | [205.41610738255 205.41610738255 206.804054054054 204.046666666667] | [13 10 9 13] | 198.15 | 114.378 | 8828.13 |
| Caltech256 | A3_SSETarget | mean | 133.25 | [213 80 102 138] | 1 | [212 79 101 137] | [213 80 102 138] | [143.694835680751 382.5875 300.06862745098 221.789855072464] | [13 8 9 11] | 385.429 | 135.411 | 7995.66 |
| Caltech256 | A4_woMultiViewFusion | mean | 81 | [116 59 66 83] | 3 | [115 58 65 82] | [116 59 66 83] | [263.853448275862 518.762711864407 463.742424242424 368.759036144578] | [11 7 7 10] | 231.253 | 0 | 3834.09 |

## 10. 搜索预算与公平性说明
| Dataset | Method | numGridConfigs | numSeeds | numRuns | searchBudget | selectionRule | selectedConfig |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=100.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A1_woBIC_Joint | 48 | 1 | 10 | 480 | best_mean_ACC_then_NMI | beta=100.0000, lambda=3000.0000, lambdaBIC=0.0000, minNodeSize=24.0000, targetView=1.0000 |
| Mfeat | A3_SSETarget | 240 | 1 | 10 | 2400 | best_mean_ACC_then_NMI | beta=100.0000, lambda=3000.0000, lambdaBIC=0.5000, minNodeSize=24.0000, targetView=1.0000 |
| Mfeat | A4_woMultiViewFusion | 80 | 1 | 10 | 800 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=2.0000, minNodeSize=40.0000, targetView=1.0000 |
| Reuters-1200 | A0_Full_Reference | Missing | 1 | 8 | Missing | 按重复评价均值+标准差上界 | beta=2000.0000, lambda=1000.0000, lambdaBIC=0.3500, minNodeSize=16.0000, targetView=1.0000 |
| Reuters-1200 | A1_woBIC_Joint | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=125.0000, lambda=100.0000, lambdaBIC=0.0000, minNodeSize=16.0000, targetView=3.0000 |
| Reuters-1200 | A3_SSETarget | 192 | 1 | 8 | 1536 | best_mean_ACC_then_NMI | beta=50.0000, lambda=300.0000, lambdaBIC=0.5000, minNodeSize=10.0000, targetView=3.0000 |
| Reuters-1200 | A4_woMultiViewFusion | 64 | 1 | 8 | 512 | best_mean_ACC_then_NMI | beta=50.0000, lambda=Missing, lambdaBIC=0.5000, minNodeSize=12.0000, targetView=4.0000 |
| WIKI | A0_Full_Reference | Missing | 1 | 8 | Missing | best_mean_ACC_then_NMI | beta=120.0000, lambda=10000.0000, lambdaBIC=4.5000, minNodeSize=30.0000, targetView=2.0000 |
| WIKI | A1_woBIC_Joint | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=100.0000, lambda=1000.0000, lambdaBIC=0.0000, minNodeSize=50.0000, targetView=2.0000 |
| WIKI | A3_SSETarget | 240 | 1 | 8 | 1920 | best_mean_ACC_then_NMI | beta=80.0000, lambda=1000.0000, lambdaBIC=2.5000, minNodeSize=30.0000, targetView=1.0000 |
| WIKI | A4_woMultiViewFusion | 80 | 1 | 8 | 640 | best_mean_ACC_then_NMI | beta=100.0000, lambda=Missing, lambdaBIC=3.5000, minNodeSize=50.0000, targetView=2.0000 |
| ForestTypes | A0_Full_Reference | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=200.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=24.0000, targetView=3.0000 |
| ForestTypes | A1_woBIC_Joint | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=100.0000, lambda=30.0000, lambdaBIC=0.0000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A3_SSETarget | 625 | 1 | 10 | 6250 | best_mean_ACC_then_NMI | beta=100.0000, lambda=30.0000, lambdaBIC=0.2000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A4_woMultiViewFusion | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=0.2000, minNodeSize=16.0000, targetView=1.0000 |
| Caltech256 | A0_Full_Reference | Missing | 1 | 3 | Missing | best_mean_ACC_then_NMI | beta=200.0000, lambda=1000.0000, lambdaBIC=3.0000, minNodeSize=120.0000, targetView=3.0000 |
| Caltech256 | A1_woBIC_Joint | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=500.0000, lambdaBIC=0.0000, minNodeSize=160.0000, targetView=3.0000 |
| Caltech256 | A3_SSETarget | 48 | 1 | 3 | 144 | best_mean_ACC_then_NMI | beta=150.0000, lambda=10000.0000, lambdaBIC=3.0000, minNodeSize=80.0000, targetView=1.0000 |
| Caltech256 | A4_woMultiViewFusion | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=Missing, lambdaBIC=4.0000, minNodeSize=160.0000, targetView=3.0000 |

- A0-best 与 ablation-mean 是混合口径。
- A0 与消融组来源不同，A0 来自 `res_biclr_refined`，消融组来自 `ablation_biclr/res`。
- 不同方法搜索空间不同；A4 没有 lambda，因此搜索空间天然不同。
- 当前报告适合作为补充观察，不适合作为严格单变量因果归因。

## 11. 结论总结
在该混合口径下，A0-best 相对消融均值的明显优势主要出现在：Mfeat/A4_woMultiViewFusion(Delta ACC=-0.3433)；Reuters-1200/A1_woBIC_Joint(Delta ACC=-0.0986)；Reuters-1200/A3_SSETarget(Delta ACC=-0.0635)；ForestTypes/A4_woMultiViewFusion(Delta ACC=-0.1405)；Caltech256/A3_SSETarget(Delta ACC=-0.0599)；Caltech256/A4_woMultiViewFusion(Delta ACC=-0.2154)。多视图融合 A4 的下降最稳定，尤其在 Mfeat、Caltech256 和 ForestTypes 上较明显，是当前最强的消融证据。A1 和 A3 的证据更具数据集依赖性，WIKI、Caltech256 或 ForestTypes 上存在接近甚至高于 A0-best 的情况，应如实报告。后续需要运行 fixed-parameter strict ablation，以排除搜索空间、选优口径和来源差异的影响。
接近 A0-best 的组合包括：WIKI/A3_SSETarget(Delta ACC=-0.0017)；ForestTypes/A3_SSETarget(Delta ACC=-0.0143)；Caltech256/A1_woBIC_Joint(Delta ACC=+0.0145)。