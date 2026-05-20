# BIC-LR-3AMVC 消融实验结果分析（best 口径）

## 1. 实验结果读取情况
- 当前结果口径：best。
- A0_Full 正式结果来源：`D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined`。
- 已读取方法：A0_Full_Reference, A1_woBIC_Joint, A3_SSETarget, A4_woMultiViewFusion。
- 已读取数据集：Mfeat, Reuters-1200, WIKI, Caltech256, ForestTypes。
- 已读取消融/A0 结果文件数：20。
- 缺失结果：None。
- 是否发现 smoke test 结果：未从结果字段中发现 smokeTest=true；但 Caltech256 A0 来源为未完整日志解析，需在论文中说明。
- 字段不一致：A0 结果来自 3AMVC-main 的 bestInfo 或文本摘要，部分字段如 AR、acceptedSplits 可能缺失；A1/A3/A4 结构较统一。
- 原论文 PDF 读取：1；补充材料 PDF 读取：1。
- Caltech256 本地原始源码 baseline：D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined4_bestacc_detail.mat。

## 2. 原论文与补充材料信息提取
- 原论文使用 ForestTypes、Reuters、MFeat、Caltech256、VGGFace2 五个数据集。
- 原论文报告 ACC、NMI、Fscore，未在主表中报告 AR、Purity、Precision、Recall、Entropy。
- 参数搜索范围：3AMVC 调整 beta 到 [10^-2, 1, 10^2]，lambda 到 [0, 10^-4, 10^-2, 1, 10^4]。
- 原始 3AMVC 使用 HBNC 生成自适应锚点，按 Eq.(8) 的锚点质量准则选择 baseline view，并进行跨视图对齐和等权融合。
- 补充材料记录 HBNC 锚点数与 baseline view：ForestTypes=[10,16,20], baseline=3；MFeat=[54,64], baseline=1；Reuters=[62,48,45,13,53], baseline=5；Caltech256=[48,67,62,45], baseline=3。
- 表格抽取状态：PDF table extraction incomplete; manual verification needed.

## 3. Caltech256 特殊说明
- 当前使用的 Caltech256 数据文件是 `catlch256_4Views_257cls_withClutter.mat` 或同名大小写变体。
- 该数据由用户自行处理，可能与原论文 Caltech256 的类别设置和预处理不完全一致。
- 因此，原论文 Caltech256 指标只作为参考，不作为正式 baseline。
- Caltech256 的正式 Original baseline 使用：`D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined4_bestacc_detail.mat`。

## 4. 主性能比较
### 主性能表
| Dataset | A0 Full | A1 w/o BIC | A3 SSE Target | A4 Single View |
| --- | --- | --- | --- | --- |
| Mfeat | 0.9270 / 0.8540 / 0.8452 | 0.9270 / 0.8540 / 0.8452 | 0.9270 / 0.8540 / 0.8452 | 0.6860 / 0.6004 / 0.4738 |
| Reuters-1200 | 0.6592 / 0.4118 / 0.3748 | 0.6108 / 0.3508 / 0.3059 | 0.6425 / 0.3816 / 0.3460 | 0.6200 / 0.3535 / 0.3227 |
| WIKI | 0.5820 / 0.5133 / Missing | 0.5855 / 0.5255 / 0.4366 | 0.5879 / 0.4974 / 0.3842 | 0.5967 / 0.5289 / 0.4022 |
| Caltech256 | 0.3043 / 0.5379 / Missing | 0.3221 / 0.5567 / 0.2157 | 0.2524 / 0.4846 / 0.1777 | 0.0913 / 0.3150 / 0.0691 |
| ForestTypes | 0.8184 / 0.5530 / 0.5677 | 0.8203 / 0.5357 / 0.5745 | 0.8375 / 0.5954 / 0.6101 | 0.7419 / 0.4390 / 0.4132 |

### 带 Original baseline 的主性能表
| Dataset | Original 3AMVC Baseline | A0 Full | A1 w/o BIC | A3 SSE Target | A4 Single View |
| --- | --- | --- | --- | --- | --- |
| Mfeat | 0.8737 / 0.8240 / Missing (paper reported 3AMVC) | 0.9270 / 0.8540 / 0.8452 | 0.9270 / 0.8540 / 0.8452 | 0.9270 / 0.8540 / 0.8452 | 0.6860 / 0.6004 / 0.4738 |
| Reuters-1200 | 0.5734 / 0.3316 / Missing (paper reported 3AMVC) | 0.6592 / 0.4118 / 0.3748 | 0.6108 / 0.3508 / 0.3059 | 0.6425 / 0.3816 / 0.3460 | 0.6200 / 0.3535 / 0.3227 |
| WIKI | Missing | 0.5820 / 0.5133 / Missing | 0.5855 / 0.5255 / 0.4366 | 0.5879 / 0.4974 / 0.3842 | 0.5967 / 0.5289 / 0.4022 |
| Caltech256 | 0.1807 / 0.4165 / 0.1121 (Original 3AMVC local run on catlch256_4Views_257cls_withClutter) | 0.3043 / 0.5379 / Missing | 0.3221 / 0.5567 / 0.2157 | 0.2524 / 0.4846 / 0.1777 | 0.0913 / 0.3150 / 0.0691 |
| ForestTypes | 0.7984 / 0.5397 / Missing (paper reported 3AMVC) | 0.8184 / 0.5530 / 0.5677 | 0.8203 / 0.5357 / 0.5745 | 0.8375 / 0.5954 / 0.6101 | 0.7419 / 0.4390 / 0.4132 |

### 结果解读
- Mfeat：A0 的 ACC/NMI/AR 为 0.9270 / 0.8540 / 0.8452。
  - A1_woBIC_Joint 相对 A0：ΔACC=+0.0000，ΔNMI=+0.0000，ΔAR=+0.0000。
  - A3_SSETarget 相对 A0：ΔACC=+0.0000，ΔNMI=+0.0000，ΔAR=+0.0000。
  - A4_woMultiViewFusion 相对 A0：ΔACC=-0.2410，ΔNMI=-0.2536，ΔAR=-0.3714。
- Reuters-1200：A0 的 ACC/NMI/AR 为 0.6592 / 0.4118 / 0.3748。
  - A1_woBIC_Joint 相对 A0：ΔACC=-0.0483，ΔNMI=-0.0610，ΔAR=-0.0689。
  - A3_SSETarget 相对 A0：ΔACC=-0.0167，ΔNMI=-0.0302，ΔAR=-0.0288。
  - A4_woMultiViewFusion 相对 A0：ΔACC=-0.0392，ΔNMI=-0.0584，ΔAR=-0.0522。
- WIKI：A0 的 ACC/NMI/AR 为 0.5820 / 0.5133 / Missing。
  - A1_woBIC_Joint 相对 A0：ΔACC=+0.0035，ΔNMI=+0.0122，ΔAR=Missing。
  - A3_SSETarget 相对 A0：ΔACC=+0.0059，ΔNMI=-0.0159，ΔAR=Missing。
  - A4_woMultiViewFusion 相对 A0：ΔACC=+0.0147，ΔNMI=+0.0157，ΔAR=Missing。
- Caltech256：A0 的 ACC/NMI/AR 为 0.3043 / 0.5379 / Missing。
  - A1_woBIC_Joint 相对 A0：ΔACC=+0.0178，ΔNMI=+0.0188，ΔAR=Missing。
  - A3_SSETarget 相对 A0：ΔACC=-0.0519，ΔNMI=-0.0533，ΔAR=Missing。
  - A4_woMultiViewFusion 相对 A0：ΔACC=-0.2130，ΔNMI=-0.2229，ΔAR=Missing。
- ForestTypes：A0 的 ACC/NMI/AR 为 0.8184 / 0.5530 / 0.5677。
  - A1_woBIC_Joint 相对 A0：ΔACC=+0.0019，ΔNMI=-0.0173，ΔAR=+0.0069。
  - A3_SSETarget 相对 A0：ΔACC=+0.0191，ΔNMI=+0.0423，ΔAR=+0.0425。
  - A4_woMultiViewFusion 相对 A0：ΔACC=-0.0765，ΔNMI=-0.1140，ΔAR=-0.1544。

## 5. BIC 惩罚有效性分析：A0 vs A1
- Mfeat：ACC=0.9270，NMI=0.8540，AR=0.8452，相对参照 ΔACC=+0.0000，ΔNMI=+0.0000，ΔAR=+0.0000。
  机制指标：平均锚点数=47.5000，targetView=1.0000，acceptedSplits=[48 45]，meanLeafSize=[40.8163265306122 43.4782608695652]，总时间=1.8608。
- Reuters-1200：ACC=0.6108，NMI=0.3508，AR=0.3059，相对参照 ΔACC=-0.0483，ΔNMI=-0.0610，ΔAR=-0.0689。
  机制指标：平均锚点数=62.0000，targetView=3.0000，acceptedSplits=[59 61 63 61 61]，meanLeafSize=[20 19.3548387096774 18.75 19.3548387096774 19.3548387096774]，总时间=20.1656。
- WIKI：ACC=0.5855，NMI=0.5255，AR=0.4366，相对参照 ΔACC=+0.0035，ΔNMI=+0.0122，ΔAR=Missing。
  机制指标：平均锚点数=44.0000，targetView=2.0000，acceptedSplits=[43 43]，meanLeafSize=[65.1363636363636 65.1363636363636]，总时间=3.0214。
- Caltech256：ACC=0.3221，NMI=0.5567，AR=0.2157，相对参照 ΔACC=+0.0178，ΔNMI=+0.0188，ΔAR=Missing。
  机制指标：平均锚点数=149.0000，targetView=3.0000，acceptedSplits=[148 148 147 149]，meanLeafSize=[205.41610738255 205.41610738255 206.804054054054 204.046666666667]，总时间=8828.1320。
- ForestTypes：ACC=0.8203，NMI=0.5357，AR=0.5745，相对参照 ΔACC=+0.0019，ΔNMI=-0.0173，ΔAR=+0.0069。
  机制指标：平均锚点数=20.0000，targetView=3.0000，acceptedSplits=[19 18 20]，meanLeafSize=[26.15 27.5263157894737 24.9047619047619]，总时间=120.6704。
A1 去掉 BIC 惩罚后，若锚点数和 acceptedSplits 增加且性能下降，可解释为过分裂倾向。BIC penalty prevents over-segmentation by penalizing excessive split complexity.

## 6. BICUnitEvidence 视图选择有效性分析：A0 vs A3
| Dataset | Result_type | A0_BIC_Target_View | A3_BIC_Target_View | A3_SSE_Target_View | Agreement | BIC_Evidence_per_View | SSE_per_View | Kendall_tau | Paper_HBNC_Baseline_View | Paper_HBNC_Anchor_Counts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | best | 1 | 1 | 1 | 1 | [0.375302261050156 0.347585808124992] | [326.004611459991 1308100.39472796] | 1 | 1 | [54 64] |
| Reuters-1200 | best | 1 | 5 | 3 | 0 | [0.0150588825150881 0.015807857721973 0.0141607895558905 0.0165869599027937 0.0171326115255762] | [713009.054896935 712614.616409023 692497.484038597 707235.961262982 695426.768835024] | 0.2 | 5 | [62 48 45 13 53] |
| WIKI | best | 2 | 2 | 2 | 1 | [0.144607572583824 0.520168532760574] | [39.9137815841716 39.6121858199667] | 1 | Missing |  |
| Caltech256 | best | 3 | 3 | 1 | 0 | [0.137441713671155 0.0808570159728149 0.180277532455593 0.0575093780070663] | [720362.201243582 42195570.5564428 18013308.652374 48409246.6963545] | 0.666667 | 3 | [48 67 62 45] |
| ForestTypes | best | 3 | 3 | 3 | 1 | [0.387441377319326 0.357820702875037 0.424387906434713] | [174935.477840684 195233.995535609 7489.82717055692] | 1 | 3 | [10 16 20] |

- Mfeat：ACC=0.9270，NMI=0.8540，AR=0.8452，相对参照 ΔACC=+0.0000，ΔNMI=+0.0000，ΔAR=+0.0000。
  机制指标：平均锚点数=47.5000，targetView=1.0000，acceptedSplits=[48 45]，meanLeafSize=[40.8163265306122 43.4782608695652]，总时间=1.6852。
- Reuters-1200：ACC=0.6425，NMI=0.3816，AR=0.3460，相对参照 ΔACC=-0.0167，ΔNMI=-0.0302，ΔAR=-0.0288。
  机制指标：平均锚点数=28.2000，targetView=3.0000，acceptedSplits=[29 27 29 25 26]，meanLeafSize=[40 42.8571428571429 40 46.1538461538462 44.4444444444444]，总时间=727.9105。
- WIKI：ACC=0.5879，NMI=0.4974，AR=0.3842，相对参照 ΔACC=+0.0059，ΔNMI=-0.0159，ΔAR=Missing。
  机制指标：平均锚点数=34.5000，targetView=2.0000，acceptedSplits=[20 47]，meanLeafSize=[136.47619047619 59.7083333333333]，总时间=2.0507。
- Caltech256：ACC=0.2524，NMI=0.4846，AR=0.1777，相对参照 ΔACC=-0.0519，ΔNMI=-0.0533，ΔAR=Missing。
  机制指标：平均锚点数=133.2500，targetView=1.0000，acceptedSplits=[212 79 101 137]，meanLeafSize=[143.694835680751 382.5875 300.06862745098 221.789855072464]，总时间=7995.6559。
- ForestTypes：ACC=0.8375，NMI=0.5954，AR=0.6101，相对参照 ΔACC=+0.0191，ΔNMI=+0.0423，ΔAR=+0.0425。
  机制指标：平均锚点数=19.6667，targetView=3.0000，acceptedSplits=[19 18 19]，meanLeafSize=[26.15 27.5263157894737 26.15]，总时间=0.5995。
A3 只将目标视图选择从 BICUnitEvidence 改为 SSEMin。若 targetView 不同且性能下降，说明复杂度校准的视图质量准则更适合 BIC-LR 锚点生成逻辑。
SSEMin 更偏向局部重构误差小的视图，而 BICUnitEvidence 同时考虑证据增益和模型复杂度。BICUnitEvidence provides a complexity-calibrated view quality criterion.

## 7. 多视图融合必要性分析：A0 vs A4
- Mfeat：ACC=0.6860，NMI=0.6004，AR=0.4738，相对参照 ΔACC=-0.2410，ΔNMI=-0.2536，ΔAR=-0.3714。
  机制指标：平均锚点数=56.5000，targetView=1.0000，acceptedSplits=[53 58]，meanLeafSize=[37.037037037037 33.8983050847458]，总时间=1.2055。
- Reuters-1200：ACC=0.6200，NMI=0.3535，AR=0.3227，相对参照 ΔACC=-0.0392，ΔNMI=-0.0584，ΔAR=-0.0522。
  机制指标：平均锚点数=25.2000，targetView=4.0000，acceptedSplits=[26 23 26 22 24]，meanLeafSize=[44.4444444444444 50 44.4444444444444 52.1739130434783 48]，总时间=159.2471。
- WIKI：ACC=0.5967，NMI=0.5289，AR=0.4022，相对参照 ΔACC=+0.0147，ΔNMI=+0.0157，ΔAR=Missing。
  机制指标：平均锚点数=26.0000，targetView=2.0000，acceptedSplits=[17 33]，meanLeafSize=[159.222222222222 84.2941176470588]，总时间=1.5726。
- Caltech256：ACC=0.0913，NMI=0.3150，AR=0.0691，相对参照 ΔACC=-0.2130，ΔNMI=-0.2229，ΔAR=Missing。
  机制指标：平均锚点数=81.0000，targetView=3.0000，acceptedSplits=[115 58 65 82]，meanLeafSize=[263.853448275862 518.762711864407 463.742424242424 368.759036144578]，总时间=3834.0874。
- ForestTypes：ACC=0.7419，NMI=0.4390，AR=0.4132，相对参照 ΔACC=-0.0765，ΔNMI=-0.1140，ΔAR=-0.1544。
  机制指标：平均锚点数=25.3333，targetView=1.0000，acceptedSplits=[24 25 24]，meanLeafSize=[20.92 20.1153846153846 20.92]，总时间=29.9225。
A4 保留 BIC-LR 锚点生成和目标视图选择，但去除跨视图对齐融合。若 A4 明显低于 A0，说明多视图融合负责把其他视图信息传递到最终聚类。Multi-view fusion is necessary for transferring the improved anchor representation to final clustering.

## 8. 机制指标分析
| Dataset | Method | Result_type | Avg_anchors | Anchor_counts_per_view | Target_view | Accepted_splits | Rejected_splits | Mean_leaf_size | Max_depth | Anchor_time | Alignment_time | Total_time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | best | 47.5 | [49;46] | 1 |  |  |  |  | Missing | Missing | 119.047 |
| Mfeat | A1_woBIC_Joint | best | 47.5 | [49 46] | 1 | [48 45] | [49 46] | [40.8163265306122 43.4782608695652] | [8 7] | 0.387714 | 1.03293 | 1.86077 |
| Mfeat | A3_SSETarget | best | 47.5 | [49 46] | 1 | [48 45] | [49 46] | [40.8163265306122 43.4782608695652] | [8 7] | 0 | 1.2246 | 1.68522 |
| Mfeat | A4_woMultiViewFusion | best | 56.5 | [54 59] | 1 | [53 58] | [54 59] | [37.037037037037 33.8983050847458] | [7 7] | 0.480126 | 0 | 1.2055 |
| Reuters-1200 | A0_Full_Reference | best | 43 | [41;42;47;38;47] | 1 |  |  |  |  | Missing | Missing | 409.531 |
| Reuters-1200 | A1_woBIC_Joint | best | 62 | [60 62 64 62 62] | 3 | [59 61 63 61 61] | [60 62 64 62 62] | [20 19.3548387096774 18.75 19.3548387096774 19.3548387096774] | [22 17 21 19 23] | 12.1451 | 7.85294 | 20.1656 |
| Reuters-1200 | A3_SSETarget | best | 28.2 | [30 28 30 26 27] | 3 | [29 27 29 25 26] | [30 28 30 26 27] | [40 42.8571428571429 40 46.1538461538462 44.4444444444444] | [14 13 10 11 9] | 13.741 | 7.11859 | 727.91 |
| Reuters-1200 | A4_woMultiViewFusion | best | 25.2 | [27 24 27 23 25] | 4 | [26 23 26 22 24] | [27 24 27 23 25] | [44.4444444444444 50 44.4444444444444 52.1739130434783 48] | [13 12 10 10 10] | 0 | 0 | 159.247 |
| WIKI | A0_Full_Reference | best | 25 | [15 35] | 2 |  |  |  |  | Missing | Missing | Missing |
| WIKI | A1_woBIC_Joint | best | 44 | [44 44] | 2 | [43 43] | [44 44] | [65.1363636363636 65.1363636363636] | [9 16] | 0.263218 | 2.32205 | 3.0214 |
| WIKI | A3_SSETarget | best | 34.5 | [21 48] | 2 | [20 47] | [21 48] | [136.47619047619 59.7083333333333] | [6 12] | 0.182028 | 1.46021 | 2.05069 |
| WIKI | A4_woMultiViewFusion | best | 26 | [18 34] | 2 | [17 33] | [18 34] | [159.222222222222 84.2941176470588] | [6 11] | 0.268523 | 0 | 1.57264 |
| Caltech256 | A0_Full_Reference | best | 115.5 | [171 78 97 116] | 3 |  |  |  |  | Missing | Missing | Missing |
| Caltech256 | A1_woBIC_Joint | best | 149 | [149 149 148 150] | 3 | [148 148 147 149] | [149 149 148 150] | [205.41610738255 205.41610738255 206.804054054054 204.046666666667] | [13 10 9 13] | 198.15 | 114.378 | 8828.13 |
| Caltech256 | A3_SSETarget | best | 133.25 | [213 80 102 138] | 1 | [212 79 101 137] | [213 80 102 138] | [143.694835680751 382.5875 300.06862745098 221.789855072464] | [13 8 9 11] | 385.429 | 135.411 | 7995.66 |
| Caltech256 | A4_woMultiViewFusion | best | 81 | [116 59 66 83] | 3 | [115 58 65 82] | [116 59 66 83] | [263.853448275862 518.762711864407 463.742424242424 368.759036144578] | [11 7 7 10] | 231.253 | 0 | 3834.09 |
| ForestTypes | A0_Full_Reference | best | 16.6667 | [17;17;16] | 3 |  |  |  |  | Missing | Missing | 522.453 |
| ForestTypes | A1_woBIC_Joint | best | 20 | [20 19 21] | 3 | [19 18 20] | [20 19 21] | [26.15 27.5263157894737 24.9047619047619] | [7 7 7] | 0.0379221 | 0.923514 | 120.67 |
| ForestTypes | A3_SSETarget | best | 19.6667 | [20 19 20] | 3 | [19 18 19] | [20 19 20] | [26.15 27.5263157894737 26.15] | [7 7 7] | 0 | 0.549527 | 0.599544 |
| ForestTypes | A4_woMultiViewFusion | best | 25.3333 | [25 26 25] | 1 | [24 25 24] | [25 26 25] | [20.92 20.1153846153846 20.92] | [8 8 8] | 0 | 0 | 29.9225 |

- A0 的旧结果部分缺少 acceptedSplits、meanLeafSize、maxDepth 等细节，因此机制分析主要依赖 A1/A3/A4 的统一结果字段。
- A4 的 alignmentTime 应为 0 或 NaN；若性能下降但时间降低，可视为效率更高但精度受损的单视图退化版本。

## 9. 搜索预算与公平性说明
| Dataset | Method | Source | Result_type | numGridConfigs | numSeeds | numRuns | searchBudget | selectionRule | selectedConfig |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| Mfeat | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=100.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 10 | 480 | best_mean_ACC_then_NMI | beta=100.0000, lambda=1000.0000, lambdaBIC=0.0000, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A3_SSETarget | 本地消融结果 | best | 240 | 1 | 10 | 2400 | best_mean_ACC_then_NMI | beta=100.0000, lambda=1000.0000, lambdaBIC=0.5000, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A4_woMultiViewFusion | 本地消融结果 | best | 80 | 1 | 10 | 800 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=1.5000, minNodeSize=24.0000, targetView=1.0000 |
| Reuters-1200 | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| Reuters-1200 | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 8 | Missing | 按重复评价均值+标准差上界 | beta=2000.0000, lambda=1000.0000, lambdaBIC=0.3500, minNodeSize=16.0000, targetView=1.0000 |
| Reuters-1200 | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=75.0000, lambda=100.0000, lambdaBIC=0.0000, minNodeSize=16.0000, targetView=3.0000 |
| Reuters-1200 | A3_SSETarget | 本地消融结果 | best | 192 | 1 | 8 | 1536 | best_mean_ACC_then_NMI | beta=50.0000, lambda=300.0000, lambdaBIC=0.5000, minNodeSize=10.0000, targetView=3.0000 |
| Reuters-1200 | A4_woMultiViewFusion | 本地消融结果 | best | 64 | 1 | 8 | 512 | best_mean_ACC_then_NMI | beta=50.0000, lambda=Missing, lambdaBIC=0.5000, minNodeSize=12.0000, targetView=4.0000 |
| WIKI | A0_Full_Reference | 本地 A0 结果（文本摘要） | best | Missing | 1 | 8 | Missing | best_mean_ACC_then_NMI | beta=120.0000, lambda=10000.0000, lambdaBIC=4.5000, minNodeSize=30.0000, targetView=2.0000 |
| WIKI | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=80.0000, lambda=100.0000, lambdaBIC=0.0000, minNodeSize=50.0000, targetView=2.0000 |
| WIKI | A3_SSETarget | 本地消融结果 | best | 240 | 1 | 8 | 1920 | best_mean_ACC_then_NMI | beta=100.0000, lambda=300.0000, lambdaBIC=3.5000, minNodeSize=20.0000, targetView=2.0000 |
| WIKI | A4_woMultiViewFusion | 本地消融结果 | best | 80 | 1 | 8 | 640 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=3.5000, minNodeSize=50.0000, targetView=2.0000 |
| Caltech256 | Original 3AMVC Baseline | 本地原始 3AMVC 源码运行结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=30.0000, lambda=300000.0000, targetView=1.0000, anchors=53,70,45,79 |
| Caltech256 | A0_Full_Reference | 本地 A0 结果（日志解析） | best | Missing | 1 | 3 | Missing | best_mean_ACC_then_NMI | beta=200.0000, lambda=1000.0000, lambdaBIC=3.0000, minNodeSize=120.0000, targetView=3.0000 |
| Caltech256 | A1_woBIC_Joint | 本地消融结果 | best | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=500.0000, lambdaBIC=0.0000, minNodeSize=160.0000, targetView=3.0000 |
| Caltech256 | A3_SSETarget | 本地消融结果 | best | 48 | 1 | 3 | 144 | best_mean_ACC_then_NMI | beta=150.0000, lambda=10000.0000, lambdaBIC=3.0000, minNodeSize=80.0000, targetView=1.0000 |
| Caltech256 | A4_woMultiViewFusion | 本地消融结果 | best | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=Missing, lambdaBIC=4.0000, minNodeSize=160.0000, targetView=3.0000 |
| ForestTypes | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| ForestTypes | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=200.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=24.0000, targetView=3.0000 |
| ForestTypes | A1_woBIC_Joint | 本地消融结果 | best | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=100.0000, lambda=30.0000, lambdaBIC=0.0000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A3_SSETarget | 本地消融结果 | best | 625 | 1 | 10 | 6250 | best_mean_ACC_then_NMI | beta=200.0000, lambda=300.0000, lambdaBIC=0.2000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A4_woMultiViewFusion | 本地消融结果 | best | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=0.2000, minNodeSize=16.0000, targetView=1.0000 |

- 主性能表对应各方法自身网格下的最优配置，不是固定 A0 配置的严格消融。
- A4 中 lambda 不适用，因此搜索空间更小，这是方法定义决定的，不应直接解释为算法优势。
- 如果某方法搜索预算与 A0 不同，性能差异应结合搜索空间和机制指标共同解释。
- 当前结果主要对应主性能口径，即每个方法在自身网格下选择最优配置。严格消融表需要在固定 A0 最优参数设置的条件下另行运行。

## 10. 结论总结
- 当前口径：best。mean 口径更适合作为论文主结果；best 口径用于补充观察最优运行潜力。
1. A1 在 1/5 个可比较数据集上 ACC 较 A0 下降超过 0.02，说明去除 BIC 复杂度惩罚通常会削弱聚类质量。
2. A3 在 1/5 个可比较数据集上 ACC 较 A0 下降超过 0.02，目标视图选择的影响具有数据集依赖性。
3. A4 在 4/5 个可比较数据集上 ACC 较 A0 下降超过 0.02，多视图融合通常是性能来源之一。
4. Mfeat: A0 相对 Original baseline 的 ΔACC=+0.0533，ΔNMI=+0.0300，ΔAR=Missing。
5. Reuters-1200: A0 相对 Original baseline 的 ΔACC=+0.0858，ΔNMI=+0.0802，ΔAR=Missing。
6. Caltech256: A0 相对 Original baseline 的 ΔACC=+0.1236，ΔNMI=+0.1214，ΔAR=Missing。
7. ForestTypes: A0 相对 Original baseline 的 ΔACC=+0.0200，ΔNMI=+0.0133，ΔAR=Missing。
- 模块贡献大小需要结合不同数据集判断；A4 的下降通常直接反映多视图融合贡献，A1 的锚点机制指标用于解释 BIC 惩罚的作用，A3 用于解释目标视图选择。

## 11. 需要复查的问题
- 缺失结果：None。
- A0 旧结果缺少部分机制字段，无法全面比较 acceptedSplits/rejectedSplits。
- PDF table extraction incomplete; manual verification needed.
- Caltech256 A0 来源为控制台日志解析，源日志只完成 240/256 条，缺少 AR/Precision/Recall/Entropy。
- Caltech256 本地 baseline 存在多个候选文件，当前选择 refined4 bestacc detail 作为正式 baseline。
- 如需严格消融，需要固定 A0 最优参数设置另行运行 A1/A3/A4 fixed 配置。
- Mfeat: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- Reuters-1200: A0 与 A3 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- Reuters-1200: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- WIKI: A0 与 A3 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- WIKI: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- Caltech256: A0 与 A3 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- Caltech256: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- ForestTypes: A0 与 A3 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。
- ForestTypes: A0 与 A4 在各自最优参数下的 anchorCounts 不一致；当前为各方法自身最优网格口径，严格消融需固定 A0 配置复跑。